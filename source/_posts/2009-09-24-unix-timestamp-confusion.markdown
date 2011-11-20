---
layout: post
title: "Unix timestamp confusion"
date: 2009-09-24 23:46
comments: true
categories: 
---

There seems to be quite some confusion when it comes to working with dates and Unix timestamps, especially when there are multiple timezones involved. I thought I would write up a bit of an explanation to help clarify the situation, and show some of the better ways to deal with this in PHP.

First up, some background information:

A Unix timestamp (or POSIX timestamp) is a measure of time, counted as a single number, representing the number of seconds since Unix Epoch, which was Midnight, 1st January 1970 UTC - continuously counting upwards from then, *kind of*. [Leap seconds](http://en.wikipedia.org/wiki/Leap_second) are dealt with by [repeating a value](http://en.wikipedia.org/wiki/Unix_timestamp#Encoding_time_as_a_number), but for our purposes you can imagine it as a linear measure of time.

> **The important thing is that no matter what the clock on the wall says, no matter where you are in the world, the Unix timestamp is the same.**

PHP uses this Unix time for all its date handling, and you can find similar constructs in many other programming languages. Here are some common PHP functions for getting and displaying the time.

```php
time();                   // gets the current Unix timestamp
date($format[, $time]);   // display the given time using
                          // $format and the server's timezone
                          // information
gmdate($format[, $time]); // display the given time using
                          // $format, assuming GMT timezone.
```

There are many benefits of encoding a date like this, but the top two would have to be for storage (a single 32-bit integer can handle all dates from December 1901 until January 2038), and for arithmetic purposes. However, the easiness by which you can mutate and play with a date is what often leads newcomers astray.

Here's an example of a good use of date arithmetic: Let's say you want to know what time it will be 47 minutes in the future.

```php
$now = time();
$future = $now + 47 * 60; // 47 minutes = 47 * 60 seconds

echo date('H:i:s', $now);       // 14:35:55
echo date('H:i:s', $future);    // 15:23:55
```

Easy!

Now here's the trap. I live in Brisbane (GMT+10) (and let's say my server is there too), but I want to display the local time for a user who is in Paris (GMT+1). The naive approach is to simply look at the difference between the server's timezone and the user's timezone and adjust the timestamp accordingly:

```php
$serverTimezone = 10;
$userTimezone = 1;

$hoursDifference = $serverTimezone - $userTimezone;

$serverTime = time();
$userTime = $serverTime - $hoursDifference * 60 * 60;

echo "Brisbane: " . date("H:i:s", $serverTime); // 14:35:55
echo "Paris: "    . date("H:i:s", $userTime)    // 05:35:55
```

Perfect! Easy right? **No!** Remember the one important thing about Unix timestamps: **no matter where you are in the world, no matter what hour of the day it is, it is still the same time and hence, the Unix timestamp is the same!** Paris isn't living 9 hours in the past, it's just that their clocks are set nine hours behind mine.

But, who cares? It works right? Yep... except when it doesn't.

```php
$serverTime = mktime(10, 59, 30, 3, 29, 2009);
$userTime = $serverTime - $hoursDifference * 60 * 60;

echo "Brisbane: " . date("H:i:s", $serverTime); // 10:59:30
echo "Paris: "    . date("H:i:s", $userTime)    // 01:59:30

// one minute later
$serverTime = mktime(11, 0, 30, 3, 29, 2009);
$userTime = $serverTime - $hoursDifference * 60 * 60;

echo "Brisbane: " . date("H:i:s", $serverTime); // 11:00:30
echo "Paris: "    . date("H:i:s", $userTime)    // 02:00:30
```

Again, it looks good, but it is forgetting one thing. In between these two times (one minute apart), all diligent and insomniac Parisians set their clocks forward an hour because of daylight savings. The time your user would want to see is actually 3:00:30, which is exactly one minute after 1:59:30 on that day.

**The better approach:**

When using the `date()` function, PHP formats the time according to its default timezone settings. The easiest way to find the current clock-time at any given location is to change the timezone settings. This means that all the naive conversions you were doing before are now unnecessary, and it will be robust to any peculiarities such as daylight savings. In the future, should France decide to move to a different timezone, your code won't need any changing either! (Though, the server might need to update its OS/PHP version or something).

```php
// this would be set by default in your php.ini file
date_default_timezone_set('Australia/Brisbane');
$time = mktime(10, 59, 30, 3, 29, 2009);

echo date("H:i:s", $time); // 10:59:30

date_default_timezone_set('Europe/Paris');

echo date("H:i:s", $time);      // 01:59:30
echo date("H:i:s", $time + 60); // 03:00:30
```

Remember that time is constant in the universe across earth, and that a Unix timestamp is a good-enough measure of that time, and that it has nothing to do with what your clock tells you. Changing your clock because of where you are on Earth doesn't affect the passage of time, and therefore altering time to get the desired clock-time is the wrong way to do things. The only time you should be using arithmetic on a timestamp is when you are actually interested in a different point in time.

Follow this basic guideline and you'll avoid a lot of headaches when dealing with different timezones.
