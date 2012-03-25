---
layout: post
title: "CitySonar"
date: 2012-03-25 19:44
comments: true
categories: 
---

This weekend was the [Amsterdam][amsmhd] [Music Hack Day][mhd], which I was lucky enough to go along to. Although the weather seemed way too nice to spend the entire weekend indoors staring at a keyboard, [plenty of people][hacks] were just as silly as me. Some of the standouts were the Theremin-controlled autotuned karaoke machine, the Bunny Boogie (where a robotic rabbit can upload recordings to SoundCloud and then will dance along to the songs you play there) and a mashup which finds popular animated gifs which match the BPM of songs in your Spotify library and synchronise the two.

I worked with [Sasha][sasha] on building an experiment we called "[CitySonar][citysonar]". The concept is simple, though perhaps hard to describe in words. Let's try anyway:

1. Choose a location on a map (we used Google Maps)
2. Choose a geographical feature, such as banks, schools or cafes.
3. A marker is placed on the screen for each of these features near you.
4. When you press play, a 'sonar' sweeps around the map and plays a note for each of the markers.

Markers further away are lower notes, ones closer are higher. Each different type of feature can have different characteristics for their notes, including the octave range, and the attack and release of the notes.

![CitySonar screenshot](https://github.com/spadgos/soundradar/raw/master/assets/screen1.png)

> **Warning full frontal nerdity:** This is a client-side app, built entirely in Javascript. The only server-side component was a small NodeJS proxy to get around cross-origin security restrictions. The data was pulled from the [OpenStreetMap][osm] XAPI, custom map tiles provided by [Stamen Maps][stamen], and client-side audio generation was done by [Audiolet][audiolet].

One great thing about the OpenStreetMap data is that it tracks heaps of geographic features, categorised quite granularly, so it's not just "bars" and "cafes" nearby, but power poles, bicycle parking, post boxes, and even brothels. Mapping these features gave some really interesting insights and some interesting results for our experiment.

For example, in a large city like Amsterdam, searching for *restaurants* will end up with a cacophony, as these tend to be clustered quite tightly in neighbourhoods. *Post boxes*, however are evenly spaced thoughout the city and actually can create something resembling a melody. Using features which are clustered in a single place (for example, embassies or brothels) can be used for a loud *hit* in your soundscape.

The quality of the project is still firmly in the "hack" category -- it went from idea to completion in 24 hours! -- but it's rather functional still, if you ignore some visual glitching... Also remember that OpenStreetMap is a community-built map and it's definitely not a complete yet: if you see features missing in your area, don't forget you can go add them yourself!

You can check it out at [http://citysonar.herokuapp.com][citysonar], and grab the code on [GitHub][gh], but my god, the code is hacky. Please don't look at it.

[amsmhd]: http://musichackday.org
[mhd]:    http://musichackday.org
[hacks]:  http://wiki.musichackday.org/index.php?title=Amsterdam_2012_Hacks
[sasha]:  http://twitter.com/#!a_kovalev
[citysonar]: http://citysonar.herokuapp.com/
[osm]:    http://wiki.openstreetmap.org/
[audiolet]: https://github.com/oampo/audiolet
[stamen]: http://maps.stamen.com/
[gh]: https://github.com/spadgos/soundradar
