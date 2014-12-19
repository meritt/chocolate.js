# Chocolate.js

[![NPM version](https://badge.fury.io/js/chocolate.js.svg)](http://badge.fury.io/js/chocolate.js) [![Dependency Status](https://david-dm.org/meritt/chocolate.js.svg?theme=shields.io)](https://david-dm.org/meritt/chocolate.js) [![devDependency Status](https://david-dm.org/meritt/chocolate.js/dev-status.svg?theme=shields.io)](https://david-dm.org/meritt/chocolate.js#info=devDependencies)

Chocolate.js is a high-customizable gallery.

## API

Inlcude chocolate style and script:

```html
<link href="/css/chocolate.css" rel="stylesheet">
<script src="/js/chocolate.js"></script>
```

Then create new instance of chocolate passing HTMLCollection to it:

```html
<script>
  var choco = new Chocolate(document.querySelectorAll('img'));
</script>
```
Chocolate automatically added all images you've passed to his gallery. Then when you click on one of this images, chocolate open the image in its gallery. You can switch between images by clicking on them thumbnails or by pressing arrow keys or by clicking on panels.

![Chocolate Layout Scheme](http://chocolatejs.ru/chocolate.svg)

There are four zones you can clik on: the image, the overlay (space above and below the image), left panel (all space from left to image and from top to thumbnails), right panel (all space from image to right edge and from top to thumbnails). You can define it by passing options to Chocolate or by setting default options for your theme.

### Options

You can create chocolate instance passing them some options:

```js
var choco = new Chocolate(document.querySelectorAll('img'), {
  "thumbnails": true,     // Show thumbnails (boolean)
  "history": true,        // Use history API (boolean)
  "repeat": true,         // Show first image after last and last before first (boolean)

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

## Build your own chocolate.js

To create your own build exec

```bash
$ grunt
```

Options:

```
--theme=name    name of theme [default]
--basedir=path  basedir for theme images [/dist/default/images]

--no-touch      compile without touch support
--no-history    compile without history api support
--no-session    compile without sessionStorage support
--no-classlist  compile without classList.js polyfill (for IE9)
```

Example:

```bash
$ grunt --theme=simonenko --basedir=/i/chocolate --no-session
```

The best way to understand chocolate theme is inspect one of the included themes. You can define most of all styles for chocolate: change backgrounds, borders, padding, margin.
But you should understand some basic mechanisms of Chocolate.js.

1. To show specified image in gallery Chocolate translate the slider (container with images) at `slide.offsetWidth*slideNumber` (see `getEnv` in `src/utils.coffee`), so all sliders should be located in line in one container.
2. To align appropriate thumbnail to center Chocolate calculate `offsetWidth` and `offsetLeft` of this thumbnail (see `chocolate.select` in `chocolate.coffee`)
3. The width of left and right panels is calculated as `((window.innerWidth - image.width) / 2)`. So if you want to fit images width to 100% of screen, you have to specify min-width for the panels. (See `themes/simonenko/css/chocolate.less`)

We moved basic CSS rules you have to use to separate file `themes/mixins.less`

## Authors

* [Alexey Simonenko](//github.com/meritt), [alexey@simonenko.su](mailto:alexey@simonenko.su), [simonenko.su](http://simonenko.su)
* [Sofia Ilinova](//github.com/isquariel), [isqua@isqua.ru](mailto:isqua@isqua.ru), [isqua.ru](http://isqua.ru)

## License

The MIT License, see the included `License.md` file.

[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/meritt/chocolate.js/trend.png)](https://bitdeli.com/free "Bitdeli Badge")
