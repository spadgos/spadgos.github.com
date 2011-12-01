---
layout: post
title: "A SoundCloud plugin for Jekyll/Octopress"
date: 2011-11-30 23:22
comments: true
categories: 
---

A little while ago, I started working at [SoundCloud][sc] -- it's a really fun place to work, and very exciting given the scale and growth of the platform there. They're so nice, they even put up an [interview with me][interview]!

I'm working across the HTML5 projects which SoundCloud are producing, including the mobile site and the widget. The widget is the player which users can embed into their websites or blogs, and just recently we've released the new version which is entirely based on HTML5. *I should mention that **very** little of the code was produced by me, since it was done before I started, but now I'm working on bugfixes and further improvements.*

Anyway, the key point here is that it's designed to be embedded on blogs. It's not very difficult to get the code to embed it normally -- just go to any track or user or anything, and click on "share" -- but since I'm now on a new blogging engine which is specifically marketed as a "hacker's" blog, I thought I'd put together a little plugin to make it even easier for those people using [Jekyll](http://jekyllrb.com/) or [Octopress](http://octopress.org/).

It's actually trivially simple in the end, but the [source is on github][plugin]. It's currently buried within my blog's repo, but maybe soon I'll move it to its own repository.

Using it is very simple too. The only downside currenly is that it requires you to know the relevant id if you want to embed a group, playlist, track or app widget. This information can be copied from the HTML which the SoundCloud site gives you, but it's not immediately obvious. Perhaps I'll see what we can do about that... The good news is that if you want a widget for a user's tracks, or *their* favorite tracks, then you can just use their username in lieu of an id.

## Examples ##

Here's the most basic usage: a resource type (`users`, `favorites`, `groups`, `playlists`, `apps`, or `tracks`), and an id. 

{% raw %}
```
{% soundcloud favorites spadgos %}
```
{% endraw %}

{% soundcloud favorites spadgos %}

There are more options, as described in the [widget documentation][widgetdocs]. *The documentation hasn't yet been updated for the new widget, and not all options there have been implemented yet. If there's one which doesn't work which you really want, let us know and we can work on it!*

{% raw %}
```
{% soundcloud groups 438 color=282828 show_artwork=true %}
```
{% endraw %}

{% soundcloud groups 438 color=282828 show_artwork=true %}

{% raw %}
```
{% soundcloud playlists 162602 show_comments=false show_playcount=false show_user=false show_artwork=false %}
```
{% endraw %}

{% soundcloud playlists 162602 show_comments=false show_playcount=false show_user=false show_artwork=false %}

{% raw %}
```
{% soundcloud tracks 26654081 %}
```
{% endraw %}

{% soundcloud tracks 26654081 %}

So there you have it. I'll write more soon about the sidebar plugin, and perhaps I may have organised my code better by then and you'll be able to get these plugins for yourself. Who knows??

[sc]: http://www.soundcloud.com/
[interview]: http://blog.soundcloud.com/2011/11/10/nick/
[plugin]: https://github.com/spadgos/spadgos.github.com/blob/source/plugins/soundcloud.rb
[widgetdocs]: http://developers.soundcloud.com/docs/widget
