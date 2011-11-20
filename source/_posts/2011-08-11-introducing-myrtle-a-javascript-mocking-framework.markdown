---
layout: post
title: "Introducing Myrtle: A Javascript Mocking Framework"
date: 2011-08-11 23:46
comments: true
categories: 
---

I'm writing to introduce a small project I've just put together. I call it **Myrtle** *(which I guess is some sort of play on words on the [Mock Turtle](http://en.wikipedia.org/wiki/Mock_Turtle))*, but in any case, it is a Javascript Mocking Framework!

The project code is available on [Github][github], or you can just grab [Myrtle.js](https://raw.github.com/spadgos/myrtle/master/Myrtle.js) if you like.

So anyway, let's look at what it does. Let's say you're writing some tests for your code, and you want to check that a particular function is called. For example, you might have a Validator class which should be called when a form input is changed. Here's the signature of a basic validation class:

```javascript
var Validator = {
    /**
     * @param {DOMElement} a HTML Input element
     * @param {String} a value to validate
     * @return {Boolean} If the value was valid.
     */
    validate : function (input, inputValue) {
        // code here
    }
};
```

The first step is to spy on the validate method:

```javascript
var info = Myrtle.spy(Validator, 'validate');
```

Spying on a method modifies it so that metadata about that method is stored with each call to it, without changing the actual functionality. You can access this metadata through the API object returned by `Myrtle.spy`.

```javascript
var info = Myrtle.spy(Validator, 'validate');

$(myInputElement).val('a changed value').trigger('change');

// let's check that validate was called
info.callCount(); // 1

// and let's see what it returned
info.lastReturn(); // true

// and let's check what the parameters passed to it were
info.lastArgs(); // [myInputElement, "a changed value"]
```

What's important to remember here is that the validate method is still executed as if nothing ever happened. Myrtle wouldn't be a good spy otherwise...

Other times you want to actually stop functions from running. For example, in a test environment, you might want to suppress error messages which you're triggering on purpose, or to stop AJAX functions from executing. In these cases, you can stub out a function.

```javascript
Myrtle.stub(Notifications, 'displayError');
```

This replaces the `displayError` method with a function which does nothing. Care should be taken in these cases that other code isn't expecting a return value from functions which you stub out completely.

You can also replace a function using stub. This is useful if you want to simulate a method, but not actually execute it - for example, when an AJAX method is called, you can put together a fake response.

```javascript
Myrtle.stub(Network, 'send', function (origFn, url, callback) {
    callback({isSuccess : true});
});
```

You'll see there that the first parameter passed to the stub function is the original method. This is useful in cases where you may want to only stub it out based on some criteria, or to modify arguments or return values of the original method.

```javascript
Myrtle.stub(
    Notifications,
    'displayError',
    function (origFn, message) {
        if (message !== 'My expected error') {
            origFn(message);
        }
    }
);
```

The last feature currently in Myrtle is some basic speed profiling. If you want to find out how fast your function is executed, or if it runs slower given some input, you can turn on profiling and find out.

```javascript
var info = Myrtle.profile(calc, 'factorial');
calc.factorial(3);
calc.factorial(8);
calc.factorial(12);

info.getAverageTime(); // a number, like 12 (ms)
info.getQuickest(); // { args : [3], ret : 6, time: 1 }
info.getSlowest(); // { args: [12], ret: 479001600, time: 20 }
```

Those are the three main features of Myrtle (so far). However, the nice thing about them is that they can all be combined in any way. You can spy on and stub out a method, or spy and profile. Stubbing and profiling probably isn't so useful though, since you'd only be measuring the speed of performing your replacement method.

There are a few ways to combine the options, and it's important to know that each of the Myrtle functions returns the *exact same* API object per function. To demonstrate:

```javascript
var info1 = Myrtle.spy(Obj, 'foo');  // turn on spying
var info2 = Myrtle.stub(Obj, 'foo'); // turn on stubbing
info1 === info2; // true
```

There's also the `Myrtle` function itself which can be used:

```javascript
var info = Myrtle(Obj, 'foo', {
    spy : true,
    stub : function () {
        // my replacement
    },
    profile : true
});
```

Of course, the last thing to cover is an important one: tidying up. Chances are that you don't want to stub out your methods for all the tests, and you want to restore them to how they were before at some point. Myrtle makes this super easy.

```javascript
// if you have a reference to the API object:
info.release();

// and even if you don't, remember that
// Myrtle will give you it easily.
Myrtle(Obj, 'foo').release();

// and if you're really lazy, just clean them all up!
Myrtle.releaseAll();

// if you're not sure if you've left
// some hanging about, just check!
Myrtle.size();
```

So, like I said, the code is on [Github][github]. Go have look and let me know what you think!

[github]: https://github.com/spadgos/myrtle
