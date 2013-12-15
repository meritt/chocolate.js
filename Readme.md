# Chocolate.js

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

```
$ grunt
```

Options:

```
--theme=name    name of theme [default]
--basedir=path  basedir for theme images [/dist/default/images]

--no-touch      compile without touch support
--no-history    compile without history api support
--no-session    compile without sessionStorage support
```

Example:

```
$ grunt --theme=simonenko --basedir=/i/chocolate/ --no-session
```

## Authors

* [Alexey Simonenko](//github.com/meritt), [alexey@simonenko.su](mailto:alexey@simonenko.su), [simonenko.su](http://simonenko.su)
* [Sophia Ilinova](//github.com/isquariel), [tavsophi@gmail.com](mailto:tavsophi@gmail.com)

## License

The MIT License, see the included `License.md` file.