---
layout: post
title: "CSSpecific plugin for SublimeText"
date: 2011-12-01 16:43
comments: true
categories: 
---

A small post to announce a small plugin for [Sublime Text 2](http://www.sublimetext.com/). It's called [**CSSpecific**][csspecific] and simply, it calculates the specificity of your CSS selectors.

## Specificiwhat? ##

When two CSS selectors target the same element, one of them has to win, right? Deciding which one is the winner is a matter of detecting which is the *most specific*. You can read the full technical details of this in the [CSS Spec](http://www.w3.org/TR/css3-selectors/#specificity), but basically it works like this:

A specificity score is 3 values. We'll refer to these values as "a,b,c".

> A selector's specificity is calculated as follows:
>
> - count the number of ID selectors in the selector (= a)
> - count the number of class selectors, attributes selectors, and pseudo-classes in the selector (= b)
> - count the number of type selectors and pseudo-elements in the selector (= c)
> - ignore the universal selector

At the end, whichever has the highest score wins, reading left to right, `a > b > c`. Note that any number of lower-valued selectors never outvalues a higher valued selector. So, even a selector which had 1000 classes in it would be less specific than one which had a single id. `(0, 1000, 0) < (1, 0, 0)`

## The plugin ##

So the plugin, when activated, reads all the CSS selectors from your file (even in HTML files), and collates them in a display panel alongside their score. For simplicity the score is presented as a single number: `a * 100 + b * 10 + c`, which means that if you DO have a selector with 1000 classes, this plugin will tell you that it has a higher score, but you know what? If you have a selector with more than 10 classes or elements, you got bigger problems, pal.

## Examples ##

```css
/* 001 */ div
/* 010 */ .active
/* 100 */ #nav
/* 101 */ #nav > ol
/* 012 */ div + a[href]
/* 002 */ a:active
```

Check it out on [github][csspecific], let me know what you think, [send bug reports][issues], pull requests... all that "social coding" stuff.

[csspecific]: https://github.com/spadgos/sublime-csspecific 
[issues]: https://github.com/spadgos/sublime-csspecific/issues 
