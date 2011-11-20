---
layout: post
title: "Converting arguments into an array"
date: 2011-09-22 23:46
comments: true
categories: 
---

I've been working on the previously-mentioned [Myrtle](http://www.github.com/spadgos/myrtle) project, as well as its unit-testing sister project, [Tyrtle](http://www.github.com/spadgos/tyrtle) (which will get further plugs soon...), and I kind of stumbled across this interesting little thing.

In javascript, there's a "magic" variable made available inside every function, called `arguments`. It appears to be an array at first glance, but it isn't. Observe:

```javascript
function f() {
    var arr = ['x', 'y']; // a real array, for comparison
   
    typeof arguments; // "object"
    typeof arr;       // "object"
   
    arguments.length; // 2
    arr.length;       // 2

    arguments[0];     // "x"
    arr[0];           // "x"
   
    typeof arguments.join;  // "undefined" !!!
    typeof arr.join;        // "function"
   
    Object.prototype.toString.call(arguments);
    // "[object Arguments]"  !!!
   
    Object.prototype.toString.call(arr);
    // "[object Array]"
}
f('x', 'y');
```

It is actually a special type of object called `Arguments`, and it's documented well on the [Mozilla Developer Network](https://developer.mozilla.org/en/JavaScript/Reference/functions_and_function_scope/arguments). Essentially, it is just an enumerable object in that it has a `.length` property and other properties in the slots `0...length - 1`, but it doesn't have `Array` as its prototype, and hence, it doesn't have any of the array functions on it.

Obviously, in most cases where you want to actually do something useful with the arguments object, you actually want to have an array, rather than this strange object. Converting it to an array is usually done like so (as is recommended in the MDN article linked above):

```javascript
var argsAsARealArray = Array.prototype.slice.apply(arguments);
```

This works. If you really wanted to be pedantic about it, you could say that it isn't actually safe, in case some code overwrites `Array.prototype.slice`, but I digress. In any case, it's a lot of typing and can be very confusing to both newbies.

> Now, in the interests of openness, I should say that I originally wrote this post to talk about this *amazing* new technique I discovered: `[].concat(arguments)`. I wrote benchmarks and everything. It was shorter and performed about 4x better on Firefox. Then I actually used it in my code and discovered that **it doesn't even work**. So, there you go. I thought I'd keep the bulk of this article and instead compare some other methods which actually do work...

I wrote some functions which convert their arguments to an array and then return it. The first two both use slice, but I wanted to see if there was a difference between creating an array literal or using the prototype *(spoiler: there isn't)*.

```javascript
function arrayProtoSlice() {
    return Array.prototype.slice.apply(arguments);
}
function arrayLiteralSlice() {
    return [].slice.apply(arguments);
}
function splice() {
    return [].splice.call(arguments, 0);
}
function push() {
    var x = [];
    x.push.apply(x, arguments);
    return x;
}
function unshift() {
    var x = [];
    x.unshift.apply(x, arguments);
    return x;
}
```

The results were interesting. I tested by calling each of the above functions with 1000 arguments.

    Operations/second; the higher the better
    Browser         Slice    Splice    Push    Unshift
    Firefox 6.0.2    4044     3549    10068      9846
    Chrome 13       37814     2701    38180     40952

Yes, some of these numbers are bizarre, but they're not typos. Push/unshift is 250% faster than slice on Firefox, and only about 10% faster on Chrome. Yes, splice is 94% slower than any other method on Chrome -- even slower than Firefox in this test. Unshift out-performs Push on Chrome by about 8%, too.

Of course, the real benefit of `[].slice.apply(arguments)` is that it's a one-liner. In real life usage, at best, the push/unshift technique requires 2 lines, but could be extracted to an external function. Of course, adding another function call is not free, so I did another benchmark.

```javascript
function convertWithPush(args) {
    var x = [];
    x.push.apply(x, args);
    return x;
}
function pushWithFnCall () {
    return convertWithPush(arguments);
}
// and the same for unshift
```

In Chrome, the extra function call led to a ~33% slow down. It did not seem to affect Firefox's performance at all, however.

In summary:

- If you want a simple one liner, go with: `var args = [].slice.apply(arguments)`
- If you want better performance, use: `var args = []; args.push.apply(args, arguments)`
- Never use splice

Please do [run the tests](http://jsperf.com/converting-arguments-to-an-array) yourself (and [here for version 2](http://jsperf.com/converting-arguments-to-an-array/2) which has the additional benchmarks). Let me know if I've forgotten a different method, or if I've stuffed up my tests somehow.
