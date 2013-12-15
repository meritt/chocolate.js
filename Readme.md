Chocolate.js
============

Chocolate.js is a high-customizable pop-up gallery.

## API

Inlcude Chocolate styles and script:

```html
<link href="/css/chocolate.css" rel="stylesheet">
<script src="/js/chocolate.js"></script>
```

Then create new instance of chocolate passing HTMLCollection to it:

```html
<script>
  new chocolate(document.querySelectorAll('img'));
</script>
```

Chocolate automatically added all images you've passed to his gallery. Then when you click on one of this images, chocolate open the image in its gallery. You can switch between images by clicking on them thumbnails or by pressing arrow keys or by clicking on panels.

### Options

You can create Chocolate instance passing them some options:
```js
new chocolate(document.querySelectorAll('img'), {
  "thumbnails": true,     // Show thumbnails (boolean)
  "history":    true,     // Use history API (boolean)
  "repeat":     true,     // Show first image after last and last before first (boolean)
  
  "actions": {            // Actions bound on click of container
    "overlay": false,     // Click on the space top and down of the image
    "leftside": "prev",   // Click on space left of the image
    "container": "next",  // Click on the image
    "rightside": "close"  // Click on space right of the image
  }
  
});
```

## Themes

Chocolate consists of four different zones: thumbnails, container with image, left panel, right panel. You can manage actions which occur when you click on one of three zones (exclude thumbnails).

You can create your own
 * stylesheets,
 * images,
 * templates,
 * options.

## Build your own Chocolate

To create your own build exec

```
$ cake build
```

Options:

```
  -t theme      name of theme [default]
  -b path       basedir for theme images [/dist/default/images]

  --no-touch    compile without touch support
  --no-history  compile without history api support
  --no-session  compile without sessionStorage support
```

Example:

```
$ cake -t simonenko.su -b /i/chocolate/ --no-touch build
```
