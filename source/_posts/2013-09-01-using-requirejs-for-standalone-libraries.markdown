---
layout: post
title: "Using RequireJS for standalone libraries"
date: 2013-09-09 20:06
comments: true
categories: 
---

Modular code is great. For both development and ongoing maintainence, it brings you many benefits, however most discussion in this area is focussed on writing modular *applications*. I want to talk about using modular code in all parts of your development, in particular when developing a standalone library. The most popular library for client-side modules is [RequireJS][requirejs], so I will focus on that.

## Case study

A few months ago, I closed a long-standing issue on a unit test framework I built, called [Tyrtle][tyrtle]: to break the source into more manageable pieces. The code had grown to almost 1500 lines and it was getting very difficult to work on. After spending a day getting it all together, in the end I had a much simpler project which was a lot more maintainable, at the cost of a couple more kilobytes. These are some things I'd recommend from my experience: there's definitely different ways to achieve the same effect, or even maybe some better practices out there, but this is what I've found so far.

## Some important questions

### Should I use modules?

It depends. If your code is of a certain size (upwards of ~600 lines), then you could probably get some benefit separating the code into modules in individual files. But below this, you have to consider that it does introduce some overhead.

Though RequireJS is quite a large library, the author, [James Burke][jrb] has thankfully produced a minimal library which provides the same interface but just a small subset of features, which will still be fine for our purposes. This is called [almond][almond] and it's only 2kb after minification. If 2kb is too significant a percentage of your library's size, then you probably should stick to a single file.

### Do I check in the compiled library?

This is up to you, and there are differing opinions here. My opinion on this is that you should.

In theory, you should be able to put your whole project on Github with a nice Makefile and README and let everyone build it for themselves, but in reality, that's more effort than most people are willing to invest, so most libraries provide a simple ready-to-go version somewhere in the repo.

*When* exactly you run the build and check in the compiled version is up to you. Some libraries will do it for every commit, others only update the precompiled version when there's an officially tagged release. If you go with updating on each commit, make sure your users know that file is not necessarily a stable version to use.

You should also decide now where the compiled version of your library will live. Sometimes it's just in the root, other times it's put into a subdirectory (named `dist`, for example), especially if there are a few different versions included in each build.

Having the built library in the repository itself will be useful if you want your library to be used with client-side package managers such as Bower.

The arguments against checking in the built library are all quite valid: in general, it is considered bad practice to check in build artefacts; and it increases confusion for other developers wanting to contribute. You will just need to weigh the ease-of-use of your library against these concerns. If you did want to avoid checking in build artefacts, yet still provide a simple version for your users, one suggestion would be to create another repository for stable releases, and use the opportunity to provide configuration tailored to a particular package manager (eg: a `component.json` file for Bower).

### Application structure

Put all your source code for the library itself into a subdirectory, called `src` or similar. All other code, including the build configuration and tests all live outside, in their own directories (`/build`, `/tests`) or in the root if there's only one or two files.

Splitting up the source files into directories can follow the same guidelines you'd use for any other project, but unless you have a very large number of modules, it is unlikely you'll need to go any deeper than just `/src`.

### AMD? CommonJS?

I recommend CommonJS. For the code to run in the browser, you'll need to use AMD modules, but converting to AMD is simple (covered below), and lets you avoid writing meaningless boilerplate. So, just like a nodejs module, just use `require`, `module` or `exports` as if they were available in scope.

```javascript
var someModule = require('someModule');

module.exports = someModule.extend();
```

## Get the libraries

Obviously in building a project with RequireJS should start with bringing in the library. Install it with [npm][npm] but make sure it's in your `package.json` file by using the `--save` flag:

```bash
$ npm install --save requirejs
```

When you install this, it will create a link to a binary of `r.js` as `node_modules/.bin/r.js`. r.js is RequireJS's command line tool for converting and combining files.

We'll also need almond, so [grab the library][almond] and put it into `/vendor`. We'll come back to this later.

## Write modular!

Start developing your library (or converting your existing one), putting each logical module of code into its own file. When there's an interdependency, you specifically import the modules you need. When it comes time to run or deploy your code, you'll need to glue it back together, which brings us to the build step.

## Automating the build

The overall goal here is to make your life easier, and as every good programmer knows, the key to an easy life is automation, so we'll configure as we go. There's a ton of systems you can choose for automation, including Makefiles, Cakefiles, Rakefiles, Jakefiles, GruntJS and more. For what we need, I recommend using a Makefile. It might not be the most intuitive interface, but it's very powerful and could win purely on ubiquity. It was created in 1977, and is widely known by developers of many different languages. This benefit is not to be underestimated: there is a ton of great documentation, community knowledge and [best practices][best-pracs] to help you along the way.

With a good Makefile (or any other tool you choose), your project's build instructions should be "Run `make`", and never "Install the node modules, then the front end modules, then copy this, then...".

## Better living through Makefiles

A Makefile is a text file which defines a number of build 'targets', each of which could depend on different targets first. Each then lists the instructions for making that target, for example copying files or compiling code. In general, the target is the path of a file - typically something which is created by that part of the build; otherwise any label can be given to a target. This is called a dummy target. If the target is a file and it exists on the file system and is up to date, then that step will be skipped.

To execute a target, you run `make [target]`, eg: `make build`, `make clean`, or simply just `make`. As a convention, the first target you should declare in a Makefile is called 'all'. This is what is executed when invoked without a target specified -- not because it's called "all" but because it's first.

One little gotcha to watch out for: the indentation is important in Makefiles, and *must be done with a tab character*. If you indent with spaces, you'll get a nasty and confusing error message, specifically: `Makefile:2: *** missing separator.  Stop.`

Starting from the start, we want the `build` step to run when you type `make`. Create a file in your directory root and name it `Makefile` (with no extension) and enter this:

```bash
all: build
```

This declares a dummy target called `all` which depends upon another dummy target named `build`. Creating targets such as this which contain no actions of their own is fine, and can often help to split up a large build process into smaller logical steps. Now we need to define the `build` target. The `build` step can be considered done if the output library file exists and is up to date, so we can add that as a target itself. To avoid repetition, it makes things easier to use variables here. Variables can be used in the target names as well as in any commands a target defines.

```bash
# target is the final output file for your library
TARGET=myLib.js
BUILD_OPTIONS=build/build.js
RJS=node_modules/.bin/r.js

all: build

build: $(TARGET)

$(TARGET):
  $(RJS) -o $(BUILD_OPTIONS) out=$(TARGET)
```

The `$(BUILD_OPTIONS)` are for the r.js tool, and we'll come to that soon, but apart from that, you've actually pretty much got everything you need: the files in the source directory are converted to AMD, combined and saved. Except...

### Declare the dependencies

Remember we said that the build process should be just `make`? Nowhere in here does it *declare* that a target depends on r.js, it just assumes it'll be in that location. The steps to make sure this exists should be added as a target and set as a dependency where needed:

```bash
$(TARGET): $(RJS)
  $(RJS) -o $(BUILD_OPTIONS) out=$(TARGET)

$(RJS):
    npm install
```

What this is saying is that to build myLib.js (`$(TARGET)`), it depends on a file existing in `node_modules/.bin/r.js` (`$(RJS)`). If it *doesn't* exist, then run `npm install`.

*Now, you'd be right in pointing out that `npm` is an undeclared dependency in this case, and that npm will in turn rely on Node. You will need to set some baseline expectation for the environment you're expecting it to be run in. For a javascript library, I think you'd be safe in assuming NodeJS and NPM are available, but that's up to you. For applications I'm working on at SoundCloud, we assume nothing (well, very very little) about the environment the code is executing in, and hence, the build script will actually download and compile Node and Nginx during a build. This is a good practice, since you can be guaranteed of the environment if you build it yourself, however I'd say it's overkill for just a library.* 

### Build only when needed

If you were to run this now, you'd see the build do its thing: the node modules downloaded and then your source files would be combined and written to the output file. Sweet! Run it again, and you'll see a message "make: Nothing to be done for \`all'". This means that make has detected that everything is up to date and so it doesn't need to do anything -- this is a key goal of a build process as it means you won't be wasting time downloading or rebuilding things which don't need it -- but hang on, how does it know it's up to date? In this case, it is looking at the dependencies of the target and sees that you now have a file in `myLib.js` and therefore its job is done. That's good, but if you change one of your source files and run make, it will happily tell you there's nothing to be done again, leaving you with an out of date library! Bummer!

To fix this, we need to tell it which files will influence the build, potentially making the final file out of date, so by collecting a list of all the source files and listing them as dependencies, an update to any one of them will make the target rebuild. Rather than manually list them all (which could be error-prone), you can just use a shell command in the Makefile.

```bash
TARGET=myLib.js
# find, in the 'src' directory, all the files with a name ending in .js
SRC_FILES=$(shell find src -type f -name "*.js")

BUILD_OPTIONS=build/build.js
RJS=node_modules/.bin/r.js

all: build

build: $(TARGET)

$(TARGET): $(RJS) $(SRC_FILES)
  $(RJS) -o $(BUILD_OPTIONS) out=$(TARGET)

$(RJS):
    npm install
```

Now run `make` and you'll see the build happening. Run it again, nothing will happen. Edit any source file, and it will build again. Perfect.

### Cleanliness...

One final thing to mention about Makefiles (and any other build automation) is they should offer a way to restore back to a "clean" state, as if make had never been executed. By convention, this is defined in a target called "clean".

```bash
TARGET=myLib.js
SRC_FILES=$(shell find src -type f -name "*.js")

BUILD_OPTIONS=build/build.js
RJS=node_modules/.bin/r.js

all: build

build: $(TARGET)

clean:
    rm -f $(TARGET)

$(TARGET): $(RJS) $(SRC_FILES)
  $(RJS) -o $(BUILD_OPTIONS) out=$(TARGET)

$(RJS):
    npm install
```

Now (once we get the r.js build options sorted), building is as simple (and as standard) as `make`.

## r.js build options

In the Makefile, we referenced a file at `build/build.js` which contains the r.js build options and now we should fill them out.

These options are an extension to the requirejs configuration, for example, setting the base path of your source files, shimming non-AMD-ready third-party modules, or defining special paths for certain module names. There are several addition options for r.js


- `include` defines a list of files to add into the build. The modules required by these files (using `require('some/module')`) will also be found by the r.js tool and automatically included in an optimal order. Here, you should include the base entry point for your library -- that is, module which exports the library itself. Here is where, you can include [almond][almond], which will provide us the basic interface needed for AMD modules to work.
- `optimize` defines which sort of minification you'd like to use.
- `cjsTranslate` will convert CommonJS modules to AMD modules
- `wrap` is the most important part of this configuration. If you were just to combine your files into one, all would be declared in global scope, quite possibly interfering with other application code (especially so if the application is using requirejs). The `wrap` configuration lets you define fragments of code to prepend and append to the combined file, and this will be how your library is exposed to the application. Using [UMD][umd] (Universal module definition), and putting its boilerplate in these fragments, we can then cater our library to whatever environment it will be used in. More on this below.

*Thorough documentation for r.js is strangely difficult to find, but the best source I've found so far is the source itself. In the r.js repo is an [example build script][rjsconfig] with good documentation on the options.*

As an example, here are the build options used for Tyrtle.

```javascript
({
  include: ["Tyrtle", "../vendor/almond"],
  optimize: "none",
  baseUrl: "src",
  cjsTranslate: true,
  wrap: {
    startFile: 'wrap-start.frag.js',
    endFile: 'wrap-end.frag.js'
  }
})
```

### UMD fragments

The UMD pattern can be implemented by using these fragments as the wrapping files in your build.

```javascript
// wrap-start.frag.js
(function (root, factory) {
  if (typeof define === 'function') {
    define(factory);
  } else if (typeof exports === 'object') {
    module.exports = factory();
  } else {
    // change "myLib" to whatever your library is called
    root.myLib = factory();
  }
}(this, function () {
```

*(Your code will be inserted here.)*

```javascript
  // wrap-end.frag.js

  // change "my-lib" to your 'entry-point' module name 
  return require('my-lib');
}));
```

To briefly explain what is happening here: it defines an IIFE which is passed root (eg: `window` in the browser), and a factory function, which returns your library. When this code is executed at the run time of the application, if that application is using a module system with `define` (AMD), or simply assigning to `module.exports` (CommonJS), your library will be accessible as a module for the application. If neither of these are used, then your library is attached to the global scope using whatever name you decide (`myLib` in the above example).

This style gives you a lot of flexibility, while keeping your code a good citizen which fits in to whatever is the style of the including application.

## Mo' builds, mo' options

By modifying the options to the r.js Makefile, you can obviously produce a range of different outputs. Here's some common options and how they could fit into a Makefile.

### Production and development builds

In the example r.js options above, as a unit test framework, Tyrtle had no need for minification, so the `optimize` option was set to "none", since it makes the builds faster and aids debugging, but what if you wanted to provide your users with both a 'development' and 'production' version of your library, to save them minifying it themselves? Simple! Let's add a new target to the Makefile.

```bash
minify: $(RJS) convert
  $(RJS) -o $(BUILD_OPTIONS) baseUrl=$(TMP_DIR) out=myLibrary.min.js optimize=uglify
```

### Mobile- or platform-specific builds

If you want to provide different builds of your system with specialised code for a particular platform, this is made simple with requirejs's `path` configuration. Though it has many uses, you can use it to dynamically alias a module name to a particular file, and r.js allows you to change this configuration on the fly.

A mobile-specific build of a library might allow you to leave out large sections of code (eg: if it were optionally interfacing with Flash), or use jQuery 2.0 instead of 1.9, since supporting old IE would no longer be necessary.

Again, it's a simple one-liner in your Makefile.

```bash
mobile: $(RJS) convert
  $(RJS) -o $(BUILD_OPTIONS) baseUrl=$(TMP_DIR) out=myLibrary.mobile.js paths.jquery="jquery-2.0.js"
```

### Custom lodash builds

If you want to use some of the functions provided by [Underscore][underscore], but are wary of increasing the file size of your library, switching to [lodash][lodash] is a good idea, since it provides Underscore compatibility, but with a powerful [customisable build process][lodash-custom]. I won't go too much into the options of lodash, but here's an example of how you might integrate it with your Makefile.

Lodash is shipped as an NPM module, and it provides an executable for generating a build, so those will need to be added as dependencies.

```bash
LODASH=node_modules/lodash/build.js
LODASH_MODULE=vendor/lodash
LODASH_LIB=$(LODASH_MODULE).js

# to access the builder, we just need the module
$(LODASH):
  npm install

$(LODASH_LIB): $(LODASH)
  $(LODASH) include=throttle,extend,bindAll exports=amd --output $(LODASH_LIB) --minify

build:
  $(RJS) {{as above}} paths._=$(LODASH_MODULE)
```

Lodash also has a `mobile` mode which could be used in combination with a mobile-specific build to further reduce file size and increase performance.

```bash
$(LODASH_LIB_MOBILE): $(LODASH)
  $(LODASH) mobile include=throttle,extend,bindAll exports=amd --output $(LODASH_LIB_MOBILE) --minify
```

## Wrapping up

If you think a modular approach to building a javascript library is a good idea -- and it probably is -- then using requirejs and a simple Makefile will let you do everything you need with minimum fuss. There are plenty more fun things you can do in a build step, but those will have to wait for another post.

[almond]: https://github.com/jrburke/almond
[best-pracs]: http://wiki.osdev.org/Makefile
[jrb]: https://github.com/jrburke
[lodash]: http://lodash.com/
[lodash-custom]: http://lodash.com/custom-builds
[npm]: https://npmjs.org/
[requirejs]: http://requirejs.org/
[rjs]: https://github.com/jrburke/r.js
[rjsconfig]: https://github.com/jrburke/r.js/blob/master/build/example.build.js
[tyrtle]: https://github.com/spadgos/tyrtle
[umd]: https://github.com/umdjs/umd
[underscore]: https://github.com/jashkenas/underscore
