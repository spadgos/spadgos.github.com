---
layout: post
title: "Smooth image loading by upscaling"
date: 2014-01-08 00:58
comments: true
categories:
published: true
---

In this post, I will discuss a technique we use at [SoundCloud][soundcloud] to make the loading of image appear smoother and faster.

The situation: soundcloud.com is a single page application which, among other things, ends up displaying a lot of users' avatars. The avatars are shown in many different situations from a tiny avatar on a waveform to a large profile image, so we have encoded the image into many different sizes. This same technique could definitely apply to [Gravatar][gravatar] images on any site.

![](/images/avatar-tiny.jpg)
![](/images/avatar-small.jpg)
![](/images/avatar-medium.jpg)
![](/images/avatar-large.jpg)

When displaying one of these images on screen, we want it to be shown to the user as fast as possible, so this technique makes use of the browser's cache of previously loaded images. Quite simply, when displaying a large avatar image, we first display a smaller version of it, stretched out to the full size, and when the large one has loaded, fade it in over the top.

In essence, the code for this looks something like this:

The template:

```html
<img class="placeholder" src="avatar-small.jpg" width="200" height="200">
<img class="fullImage"   src="avatar-large.jpg" width="200" height="200">
```

The CSS (for brevity, I'm not including the positioning code here, but they should lie atop one another):

```css
.fullImage {
  transition: opacity 0.2s linear;
}
```

... and the javascript:

```javascript
var fullImage   = $('.fullImage'),
    placeholder = $('.placeholder');

fullImage
  .css('opacity', 0)
  .on('load', function () {
    this.style.opacity = 1;
    setTimeout(placeholder.remove.bind(placeholder), 500);
  });
```

<div id="imgDemo" style="position: relative; width: 200px; margin: auto;" class="flash-video">
  <img class="placeholder" src="/images/avatar-small.jpg"   width="200" height="200"
    style="background-color: #f0f; border: 0;"
  >
  <img class="fullImage"   src="/images/avatar-large.jpg" width="200" height="200"
    style="background-color: #0f0; border: 0; position: absolute; top: 0; left: 0; -webkit-transition:opacity .2s linear;-moz-transition:opacity .2s linear;-o-transition:opacity .2s linear;transition:opacity .2s linear"
  >
  <label style="font-size: 75%">Simulate:</label> <button class="load">Load</button>
  <button class="reset" disabled>Reset</button>
</div>

<script type="text/javascript">
(function () {
  var fullImage = $('#imgDemo .fullImage')[0],
      smallImage = $('#imgDemo .placeholder')[0];
  fullImage.style.opacity
    = smallImage.style.opacity
    = 0;

  $('#imgDemo .reset').click(
    function () {
      $('#imgDemo .reset')[0].disabled = 'disabled';
      $('#imgDemo .load')[0].disabled = false;
      fullImage.style.opacity
        = smallImage.style.opacity
        = 0;
    }
  );
  $('#imgDemo .load').click(
    function () {
      $('#imgDemo .reset')[0].disabled = false;
      $('#imgDemo .load')[0].disabled = 'disabled';
      smallImage.style.opacity = 1;
      setTimeout(function () {
        fullImage.style.opacity = 1;
      }, 300);
    }
  );
}());
</script>

In the end, not too complicated, and it gives a nice effect to the loading of your images. But there's a problem here: we don't want to make a request to get the small image just to show it for a couple of milliseconds. The overhead of making HTTP requests means that loading the larger image will usually not take significantly longer than the small one. So, therefore it only makes sense to use this technique if a smaller image has already been loaded in this session (and hence, will be served from the browser's cache). But how do we know which images are probably in cache?

Each time an avatar is loaded, we need to keep track of that, but over time, there could be many thousands of avatars loaded in one session, so it needs to be memory efficient. Instead of tracking the full URLs of loaded images, we extract just the minimum amount of information to identify a image, and use a bitmask to store which sizes have been loaded.

```
// a simple map object, { identifier => loaded sizes }
var loadedImages = {},
    
    // Let's assume a basic url structure like this:
    // "http://somesite.com/{identifier}-{size}.jpg" 
    imageRegex = /\/(\w+)-(\w+)\.jpg$/,
    
    // a list of the available sizes.
    // format is [pixel size, filename representation]
    sizes = [
      [ 20, 'tiny'  ],
      [ 40, 'small' ],
      [100, 'medium'],
      [200, 'large' ]
    ];

// extract the identifier and size.
function storeInfo(url) {
  var parts = imageRegex.exec(url),
      id    = parts[1]
      size  = parts[2],
      index;
  
  // find the index which contains this size
  sizes.some(function (info, index) {
    if (info[1] === size) {
      loadedImages[id] |= 1 << index;
      return true;
    }
  });
}

// once the image has loaded, then store it into the map
$('.fullImage').load(function () {
  storeInfo(this.src);
});
```

So let's take a look at what's happening there. When the image loads, we extract the important parts from the url: namely the identifier and the size modifier. Each size is then mapped to a number -- its index in the `sizes` array -- and the appropriate bit is turned on in the loadedImages map. The code on line 27 does this conversion and bit manipulation. `1 << index` is essentially the same as `Math.pow(2, index)`. By storing only a single number in the object, we actually can save quite a bit of memory. A single number object could contain many different flags. For example, assume we have four different sizes and 10,000 images in the map:

```javascript
asBools = {
  a: [true, true, false, true],
  b: [false, true, false, false],
  // etc...
};

asInts = {
  a: 11,  // 2^0 + 2^1 + 2^3 = 1 + 2 + 8
  b: 2,   // 2^1
  // etc...
}
```

The memory footprint of these two objects differ 30%: 1,372,432 bytes for the booleans, and 1,052,384 for the integers. The greatest amount of memory used in these is actually for the key names, so depending on how you identify the images, compressing that as much as possible will also help. Numeric keys are stored particularly efficiently by V8.

So anyway, back to the issue. We now have a map showing us which images have been loaded during this session, so it's time to use that information for choosing a placeholder.

```javascript
// find the largest image smaller than the requested one
function getPlaceholder(fullUrl) {
  var parts = imageRegex.exec(fullUrl),
      id = parts[1],
      targetSize = parts[2],
      targetIndex;

  sizes.some(function (info, index) {
    if (info[1] < targetSize) {
      targetIndex = index;
      return true;
    }
  });

  while (targetIndex >= 0) {
    if (loadedImages[id] & 1 << targetIndex) {
      return fullUrl.replace(/\w+\.jpg$/, sizes[targetIndex][1] + '.jpg');
    }
    --targetIndex;
  }
}

// and in usage:
var placeholderUrl = getPlaceholder(fullSizeUrl);

if (placeholderUrl) {
  // there has been a smaller image loaded previously, so...
  addTheFadeInBehaviour();
} else {
  // no smaller image has been loaded so...
  loadFullSizeAsNormal();
}
```

This technique is not completely basic, and I've deliberately glossed over some of the finer details, but it can create a very nice effect on your site, and is especially effective for long-lived single-page apps. I hope you find it useful.

[soundcloud]: https://soundcloud.com
[gravatar]: http://gravatar.com
