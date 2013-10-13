## History

The web has come a long way since the 90s, when something like this was considered cutting edge (Space jam). Javascript was created in 1995, but it was relegated to toy scripts and annoyances for a long time. Scripts at this time were usually quite short, and often just written inline on the page, often just copied from sites like Dynamic Drive.

This continued until Gmail came along in 2004, and people finally started realising the real power in Javascript. As more people started exploring the possibilities, the amount of Javascript used in sites steadily increased over the years. Thankfully, it started to be developed in separate files instead of inline, but the standard way to deliver these files was by writing all the scripts into the head.

It was a couple of years after this around 2007, that we started to think more about how the code we were writing was being sent to the browser. Writers such as Steve Souders started advocating some best practices, and tools like YSlow emerged to point out the failings in the current approach. Things such as reducing HTTP requests by combining all JS files, then followed by basic minification by stripping whitespace and comments became commonplace. Both of these practices continued to develop further, and with Javascript parsers getting better all the time, minification (or uglification) has progressed to the point we're at today. "if you don't know what to uglify is, you are a simpleton".

The standard workflow now was to get a minification tool like Uglify, YUI Compressor or Google Closure Compiler and roll your entire source directory into one big file. It meant that you had well compressed code with one HTTP request, but that might include a lot of files which you didn't actually need on that page, or even at all in your application.

In the last two years, especially as single page applications and node have become more popular, finally the concepts of modular code made its way into common use, with AMD and CommonJS styles being served to the browser with tools like requirejs and browserify. Along with all the other benefits of modular code, by using these techniques, it gives the ability for tools to use the dependency information to generate a more streamlined build.

(
    example, showing the difference in styles: 
    - roll whole directory
    - add dependency information
    - change dependencies -> smaller build
)

And so this brings us to where we are today, but my talk is not about how we got here, but what we can do with these tools to make even better builds.

## Optimisations

One thing to remember is that a good build process for your application will produce many performance optimisations, beyond simply reducing the size of your javascript files. Some of these optimisations are straightforward, however many of them will require you to change the way that you write code, or limit the features of the language that you can use. This might sound drastic, but you probably already limit yourself in some ways. For example, to do any form of minification at all, then using `eval` must be completely avoided, as the local variable names can not be reliably changed. Browsers already do a very good job at optimising your code for execution, but they must still support the full set of language features, which limits their effectiveness. By dropping some features, you can open up some extra performance gains.

### Asset hashing

When I talk about assets here, I'm referring to any file which doesn't change after the deployment, so this would include images, css, javascript and so on. If it's not dynamically generated for each request, then it's a static asset.

One problem I'm sure every web developer has once faced is with cache invalidation, due to reusing filenames between deployments. A common technique to bust that would be to request the files with an incrementing counter or a timestamp in a query parameter. There are a few problems here: firstly, if you increment the counter for all assets, that means you invalidate the cache of all the files on each deploy, even if the files hadn't changed. Also, depending on how your delivery network is set up, it is possible that the query parameters are not taken into consideration for the cache keys.

A safer solution, and one which is guaranteed to work, is for the build process to put a unique identifier into the filenames of each asset as they are copied to the target directory. As an identifier, you could use a simple hash of the contents, or even the git SHA of the last commit to affect that file. This means that you are definitely tying an exact version of the file to a unique name. If the file contents change, then you'll get a new file name and be guaranteed to never receive an out-of-date cache. All assets, including your JS, images and so on can all be served with cache headers set for a year or more.

Another benefit in doing this is that you can keep multiple versions of the file available. If you are building a single page application, this can be quite important, since the clients are never refreshing the page while they use your app, they are never receiving the updated code. During this time, if they were to come to a page with an asset which has been changed since their session started, they'd get a 404. You might not think it's such a problem at first, but at SoundCloud, we've seen users running versions of our app that is four or five weeks out of date, meaning they haven't refreshed the page in that long.

One problem here though, is updating references to the assets in your code. For example, if you have a CSS file referring to `/assets/imgs/bullet.png`, you need the build script to change the CSS to point to `/assets/imgs/bullet-1a2b3c.png`. This is fairly simple with CSS, since a basic regex can find all the `url()` strings and rewrite them. For references from JS however, it's a little more complicated, since you need a way to find the strings you can rewrite. At SoundCloud, we've done this by introducing a helper method called `__ASSET()` which identifies strings which are referring to an asset on the disk. This function takes a single literal string, and during development time, it simply returns the same value.

`function __ASSET(path) { return path }`

During the build step though, it's easy to use the AST to find calls to this method and then rewrite the string inside.

`__ASSET(/assets/imgs/bullet.png) --> '/assets/imgs/bullet-1a2b3c.png'` *show ast code?*

One small annoyance of this method is that you can't dynamically build a path to an asset, since the build script needs to be able to statically find the value of the string. This means that you might have some code that looks like this:

    defaults['20x20'] = __ASSET('/assets/imgs/default_20x20.png'); 
    defaults['50x50'] = __ASSET('/assets/imgs/default_50x50.png'); 
    defaults['100x100'] = __ASSET('/assets/imgs/default_100x100.png'); 

But it's a very small price to pay for never having to worry about your cache again. A nice little side-effect of this is that it essentially makes you explicitly state your asset dependencies, so when an asset is no longer used, that can be identified very easily and you can remove it from your repository.

### Bucketing, for caching and network gain

One very simple and effective optimisation you can use is that instead of rolling all the javascript source into one giant file, divide your files into three or four buckets. At SoundCloud we do this simply with a regular expression on the name of the source file, and use three buckets: one for all of the views and their templates, one for all third party vendor files and one for all the rest. The effect here is twofold: it's likely that you won't be changing the vendor files very often, so with the hash in their filename, they will remain cached between deployments. And by splitting your application code into parts, the code can be downloaded in parallel by the browser, meaning less delay to start the app. 

### Domain sharding

Domain sharding is a technique that's been investigated and written about by Steve Souders a couple of times in the last few years. It works on the knowledge that browsers will only open a certain number of connections to a single host. It varies per browser, but these days it's around 6-8 connections per host. If you try to open more connections than that, the extra ones will have to wait until there's an available slot for that domain. *diagram*

Domain sharding is the process of moving your assets across multiple domains to circumvent this limitation. Though there is an additional cost up front with an extra DNS lookup, Steve's study showed that by using about 4 domains to serve assets is the optimal number. Above this level, the DNS lookups and total load on the network end up producing worse results.

If you are using the technique before of rewriting asset references, then this is very basic. You simply rewrite the asset link by adding a domain to make it an absolute URL. All you need to do is create 4 subdomains which all map to the same directory on your web server, and then assign each asset to one of them. You'd want to do this in a deterministic manner so that between deploys an asset stays on the same host, otherwise the cache will have been invalidated. By this, I just mean a simple way to divide a file into each bucket, so that you have roughly the same number of files per bucket, and one file will always end up in the same bucket. You could just do a checksum on the filename or its contents and then get the modulo value to decide.

`__ASSET('/assets/img/bullet.png') --> '//assets1.mydomain.com/assets/img/bullet-1a2b3c.png'`
`__ASSET('/assets/img/logo.png') --> '//assets3.mydomain.com/assets/img/logo-4d5e6f.png'`

When we did this on soundcloud.com for serving user avatars on the waveform, we saw a 30% increase in performance, for something that took 10 minutes to set up.

(http://www.stevesouders.com/blog/2013/09/05/domain-sharding-revisited/)

### Lazy code evaluation

Tobie Langel is a front end engineer at Facebook and he wrote an article about 2 years ago about using lazy evaluation of AMD modules for performance gain. The idea here is that even if you have minified and gzipped code which is already cached in the browser, when your application starts, the browser has to actually interpret all the code which ends up taking a not insignificant amount of time.

He proposed to that instead of puting all the javascript of each module into a function to define that module, during a build process, rewrite it into a string. This means that when the javascript interpreter encountered the start of the string, all it would need to do would be to find the end of the string, and not have to build any structures or execute any code. By adding only 2 or 3 lines into the AMD loader, when a module is required for the first time, then the string would be evaluated, essentially deferring the interpretation until it is actually needed.

Doing this in a build step is really simple: you minify the code as normal, then just find the body of each `define` call and convert it to a string. *code*

We implemented this on soundcloud.com, but removed it a few months ago for a few reasons. Firstly, it made debugging very difficult outside of the webkit inspector, but mostly because we found out that it actually made things slower in Chrome. Turns out Chrome does this sort of optimisation by itself: when it finds a function, like the body of a module, the interpreter simply skips over to find the end of the function. Only when the function is executed for the first time does it evaluate the contents.

There's a good lesson here to remember to continually check that your optimisations are still optimal.

### Lazy require calls

This is an example of a very standard method of writing modular code:

    var URLHelper = require('lib/url-helper'),
        View      = require('lib/view'),
        Router    = require('router'),
        Config    = require('config');

    module.exports = View.extend({
        onClick: function () {
            Router.navigate(
                URLHelper.stringify([
                    Config.get('baseUrl'),
                    this.id // or whatever
                ])
            );
        }    
    });

At the top of the file, you require all the modules that you need for this particular class, and then in the definition and runtime of the class you use those modules. The problem here is that in defining this class, we actually only need one of those modules. It's just the `View` module which is used right away, and the other three are only ever referred to when or if the user actually clicks on this view.

If the modules were only required when we actually needed to use them, that might save or at the very least, delay a heap of processing, however putting the `require` statements at each place where you need the external module makes the code difficult to read, and can be very repetitive. Thankfully, AST manipulation can do this for us.

The process here would be in two parts. Firstly, find all variable declarations where a variable is being set to the value of a call to `require`. One walk over the tree could identify these and create a simple mapping:

    {
        URLHelper: 'lib/url-helper',
        View: 'lib/view',
        Router: 'router',
        Config: 'config'
    }

Then another pass over the tree could find all references to these variables and change them by adding the require call at that moment. Because function calls aren't free, you could also just save these modules to the same variable names as before. The code then becomes:

    var URLHelper,
        View,
        Router,
        Config;

    module.exports = (View || View = require('lib/view')).extend({
        onClick: function () {
            (Router || Router = require('router')).navigate(
                (URLHelper || URLHelper = require('lib/url-helper')).stringify([
                    (Config || Config = require('config')).get('baseUrl'),
                    this.id
                ])
            );
        }
    });

This is functionally identical code, but it means that you're delaying the evaluation of possibly very large sections of your application code until it is actually necessary.

### Targeting different environments

Depending on what you're working on, it might be worthwhile to produce several target builds. For example, a mobile-specific build, or one for modern browsers. By cutting out fallbacks for older browsers, this could save you both bandwidth and increase runtime performance for your app. This is becoming more common now in popular libraries, with jQuery and Lodash both providing custom builds for these environments. During your build step, you could modify your requirejs configuration to alias these libraries to point to a particular version, thereby including the minimal amount of code needed.

At runtime then, you could use feature detection or browser sniffing to decide which version to deliver to the client.

## Build your own ??

- intro to the AST

- SoundCloud homepage = 1,187,582 bytes
- Twitter homepage = 1,230,310 bytes
- Facebook homepage = 2,550,197 bytes

- optimisations are never free - require you to stop using certain techniques which are valid

- custom mobile build (lodash, resize pictures)


- seq for async handling

- build script for linting (of sorts)
