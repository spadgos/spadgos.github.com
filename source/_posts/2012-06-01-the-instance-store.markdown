---
layout: post
title: "The instance store"
date: 2012-06-01 18:20
comments: true
categories: 
published: false
---

After giving [my talk][sfjs] at Fluent and SFJS this week, I was really interested to see what people wanted to know more about. I thought I might start a little series to go into the details of some of the techniques which were of interest.

The thing I was asked about the most was what we call the "instance store" for our models. I'm not really surprised that this came up, since my slide introducing was just this:

```javascript
s1 = new Sound({id: 123, title: 'Foo'});
s2 = new Sound({id: 123, bpm: 120});
s1 === s2; // true
```

For those who haven't done messed up things in Javascript before, it's a bit strange. First I guess I should back up and explain what the store is and why we use it though.

In the [Next SoundCloud][next], we construct the page out of a series of nested views. It's almost guaranteed that on any one page, there will be several views of the same model. For example, on the "listen" page of a sound, we'd have one view each for the title, the play, like and repost buttons, the waveform (and so on). We don't want to duplicate this data on each view. Also, to keep the initialisation of these as simple as possible, we just want to pass the id of the model to each view. Putting this together, it's clear that what is needed is a way to grab a (possibly already-created) instance of a model just by using its id.

![](/images/instance-store/player.png)

So, the instance store is simply an in-memory object which holds a reference to every instance of a model that we've created. We have a wrapper class around it to provide some convenience methods (`get`, `set`, `has` and so on), but in essence it's just a plain old map. Where the strangeness kicks in is in a little-known feature of Javascript's `new` operator. If a constructor returns something (*anything*), then that's what you get. So, our models' constructors are doing something like this *(grossly simplified for clarity)*:

```javascript
var store = {};

function SomeModel(attributes) {
  var id = attributes.id;
  if (store[id]) {     // does it already exist?
    return store[id];  // give back the original instance
  }
  store[id] = this;    // save this instance to the store
}
```

Now this pattern isn't particularly new. It's very common in other languages to use a factory method for constructing/accessing instances, especially when working with the Singleton pattern, however Javascript gives you the ability to perform such <strike>abuses</strike> magic, and the expressiveness it adds makes using it something a developer doesn't even need to think about.  

## Tidying up

When you're building a single-page application, the goal is that the user will never hit that refresh button, and given the way which you'd use SoundCloud, it's not uncommon for a single session to last several hours. If these stores are hanging onto every single Sound, User and *Comment*, there's going to be tens of thousands of unused models sitting around taking up precious memory, so we need to get rid of the models which aren't needed anymore. The way this is done is by keeping a usage count for each instance. The counter is incremented whenever `new` is called, and manually decremented whenever the instance isn't needed. Periodically, we check the store to see if there are any models with a count of zero, and they're purged from the store, allowing the browser's garbage collector to free up the memory. This usage count is encapsulated in the store object, but in essence it's something like this:

```javascript
var store = {},
    counts = {};

function SomeModel(attributes) {
  var id = attributes.id;
  if (store[id]) {
    counts[id]++;
    return store[id];
  }
  store[id] = this;
  counts[id] = 1;
}

SomeModel.prototype.release = function () {
  counts[this.id]--;
}
```

The reason for performing the cleanup on a timer, rather than whenever a usage count hits zero is so that the model stays in the store when you switch views. If you navigate to another page, there will be a single moment between cleaning up the existing views and setting up the new ones when every single model's count is zero. The new page might actually contain views of one or more of these models, so it'd be quite wasteful to remove them instantly.

The "manual" decrementing isn't quite as error-prone as it sounds. The base View class we use checks to see if it has a model, and calls `release()` upon it when the view is destroyed. As a developer working with the system, you only need to worry about it if you're doing something a little funky. This obviously does open the door for some careless code to create memory leaks, but the benefits greatly outweigh the potential drawbacks.

[sfjs]: /blog/2012/06/01/soundclouds-stack-slides-from-fluentconf-and-sfjs/
[next]: http://next.soundcloud.com
