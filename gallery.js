(function() {
  var Gallery, closeAction, counter, existActions, isHistory, nextAction, prevAction, templates;
  var __hasProp = Object.prototype.hasOwnProperty, __indexOf = Array.prototype.indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (__hasProp.call(this, i) && this[i] === item) return i; } return -1; };

  templates = {
    overlay: '\
<div class="sgl-overlay">\
  <div class="sgl-leftside"></div>\
  {{spinner}}\
  <div class="sgl-container"></div>\
  <div class="sgl-rightside"></div>\
  {{thumbnails}}\
  <div class="sgl-close"></div>\
</div>\
',
    spinner: '\
<div class="sgl-spinner">\
 <img src="../themes/default/images/spinner-bg.png" alt="">\
 <img src="../themes/default/images/spinner-serenity.png" alt="">\
</div>\
',
    thumbnails: '\
<div class="sgl-thumbnails"></div>\
',
    thumbnail: '\
<div class="sgl-thumbnail{{selected}}" data-cid="{{cid}}" style="background-image:url(\'{{thumbnail}}\')"{{title}}></div>\
',
    header: '\
<div class="sgl-header"><h1>{{title}}</h1></div>\
',
    hover: '\
<span class="sgl-item-hover" data-sglid="{{cid}}"></span>\
'
  };

  counter = 0;

  nextAction = 'next';

  prevAction = 'prev';

  closeAction = 'close';

  existActions = [nextAction, prevAction, closeAction];

  isHistory = !!(window.history && history.pushState);

  Gallery = (function() {

    Gallery.prototype.images = {};

    Gallery.prototype.current = null;

    Gallery.prototype.options = {
      actions: {
        overlay: false,
        leftside: prevAction,
        container: nextAction,
        rightside: closeAction
      },
      thumbnails: true
    };

    /*
       Конструктор
    */

    function Gallery(images, options) {
      var element, elements, template, _i, _j, _len, _len2, _ref;
      var _this = this;
      if (options && typeof options === 'object') {
        this.options = $.extend(this.options, options);
      }
      template = templates.overlay;
      template = template.replace('{{spinner}}', templates.spinner);
      template = template.replace('{{thumbnails}}', this.options.thumbnails ? templates.thumbnails : '');
      this.overlay = $(template).appendTo('body');
      elements = ['container', 'spinner', 'leftside', 'rightside'];
      if (this.options.thumbnails) elements.push('thumbnails');
      for (_i = 0, _len = elements.length; _i < _len; _i++) {
        element = elements[_i];
        this[element] = this.overlay.find('.sgl-' + element);
      }
      this.overlay.find('.sgl-close').click(function(event) {
        return _this.close();
      });
      _ref = ['overlay', 'container', 'leftside', 'rightside'];
      for (_j = 0, _len2 = _ref.length; _j < _len2; _j++) {
        element = _ref[_j];
        this._prepareActionFor(element);
      }
      if (isHistory) {
        $(window).bind('popstate', function(event) {
          var cid, hash;
          hash = window.location.hash;
          cid = hash ? parseInt(hash.replace('#image', ''), 10) : 0;
          if (cid > 0) {
            if (_this.current === null) {
              return _this.show(cid);
            } else {
              return _this.updateImage(cid, false);
            }
          }
        });
      }
      $(window).bind('keyup', function(event) {
        if (_this.overlay.css('display') === 'block') {
          switch (event.keyCode) {
            case 27:
              return _this.close();
            case 37:
              return _this.prev();
            case 39:
              return _this.next();
          }
        }
      });
      if (images) this.add(images);
    }

    Gallery.prototype._prepareActionFor = function(element) {
      var method, verify, _ref;
      var _this = this;
      method = (_ref = this.options.actions[element], __indexOf.call(existActions, _ref) >= 0) ? this.options.actions[element] : false;
      if (method) {
        verify = this[element].attr('class');
        this[element].click(function(event) {
          if ($(event.target).hasClass(verify)) return _this[method]();
        });
      }
      return this;
    };

    /*
       Добавляем список изображений для работы в галереи
    */

    Gallery.prototype.add = function(images) {
      var image, object, _i, _len;
      if (!images || images.length === 0) return this;
      for (_i = 0, _len = images.length; _i < _len; _i++) {
        object = images[_i];
        image = null;
        if (object instanceof HTMLElement) {
          image = $(object);
          object = {
            source: image.attr('data-src') || image.parent().attr('href'),
            title: image.attr('data-title') || image.attr('title'),
            thumbnail: image.attr('src')
          };
        }
        this._addToGallery(object, image);
      }
      return this;
    };

    Gallery.prototype._addToGallery = function(data, image) {
      var cid, preload, showFirstImage;
      var _this = this;
      if (!data.source) return;
      cid = ++counter;
      if (!data.thumbnail) data.thumbnail = data.source;
      this.images[cid] = data;
      if (image) {
        showFirstImage = function(event, cid) {
          event.stopPropagation();
          event.preventDefault();
          return _this.show(cid);
        };
        image.addClass('sgl-item').click(function(event) {
          return showFirstImage(event, cid);
        });
        preload = new Image();
        preload.src = data.thumbnail;
        return preload.onload = function(event) {
          image.before(templates.hover.replace('{{cid}}', cid));
          return $('[data-sglid=' + cid + ']').css({
            width: image.width(),
            height: image.height()
          }).click(function(event) {
            return showFirstImage(event, cid);
          });
        };
      }
    };

    /*
       Показать изображение на большом экране
    */

    Gallery.prototype.show = function(cid) {
      if (cid == null) cid = 1;
      if (this.images[cid] == null) throw 'Image not found';
      if (this.current === null) this.current = cid;
      if (this.options.thumbnails) this.createThumbnails();
      this.updateImage(cid);
      this.overlay.css('display', 'block');
      return this;
    };

    Gallery.prototype.close = function() {
      this.overlay.css('display', 'none');
      return this;
    };

    Gallery.prototype.next = function() {
      var next;
      next = this.current + 1;
      if (this.images[next] != null) this.updateImage(next);
      return this;
    };

    Gallery.prototype.prev = function() {
      var prev;
      prev = this.current - 1;
      if (this.images[prev] != null) this.updateImage(prev);
      return this;
    };

    /*
       Обновление изображения
    */

    Gallery.prototype.updateImage = function(cid, updateHistory) {
      var title;
      if (updateHistory == null) updateHistory = true;
      this.current = cid;
      if (this.options.thumbnails) {
        this.thumbnails.find('.selected').removeClass('selected');
        this.thumbnails.find('[data-cid=' + cid + ']').addClass('selected');
      }
      if (isHistory && updateHistory) {
        title = this.images[cid].title ? 'Image: ' + this.images[cid].title : null;
        history.pushState(null, title, '#image' + cid);
      }
      this.getImageSize(cid, function(cid) {
        var image;
        image = this.images[cid];
        this.updateDimensions(image.width, image.height);
        this.container.css('background-image', 'url(' + image.source + ')');
        return this.container.html(image.title ? templates.header.replace('{{title}}', image.title) : '');
      });
      return this;
    };

    /*
       Обновление размеров блока с главным изображением
    */

    Gallery.prototype.getImageSize = function(cid, after) {
      var element, image;
      var _this = this;
      if (after == null) after = function() {};
      image = this.images[cid];
      if (!image.width || !image.height) {
        this.spinner.css('display', 'block');
        element = new Image();
        element.src = image.source;
        return element.onload = function(event) {
          _this.spinner.css('display', 'none');
          _this.images[cid].width = element.width;
          _this.images[cid].height = element.height;
          delete element;
          return after.call(_this, cid);
        };
      } else {
        return after.call(this, cid);
      }
    };

    /*
       Обновление размеров блока с главным изображением
    */

    Gallery.prototype.updateDimensions = function(width, height) {
      var innerHeight, innerWidth, left, style, thumbnails, top, windowHeight, windowWidth;
      thumbnails = this.options.thumbnails ? this.thumbnails.height() : 0;
      innerWidth = window.innerWidth;
      windowWidth = innerWidth - 50;
      innerHeight = window.innerHeight;
      windowHeight = innerHeight - 50 - thumbnails;
      if (width > windowWidth) {
        height = windowWidth * height / width;
        width = windowWidth;
      }
      if (height > windowHeight) {
        width = windowHeight * width / height;
        height = windowHeight;
      }
      left = parseInt(width / 2, 10);
      top = parseInt(height / 2, 10);
      if (thumbnails > 0) top += parseInt(thumbnails / 2, 10);
      style = {
        'width': (innerWidth / 2 - left) + 'px',
        'height': innerHeight + 'px'
      };
      this.leftside.css(style);
      this.rightside.css(style);
      style = {
        'width': width,
        'height': height,
        'margin-left': '-' + left + 'px',
        'margin-top': '-' + top + 'px'
      };
      this.container.css(style);
      this.spinner.css(style);
      return this;
    };

    /*
       Создание панели для тумбнейлов
    */

    Gallery.prototype.createThumbnails = function() {
      var cid, content, current, image, selected, _ref, _this;
      if (!this.options.thumbnails || !this.current || this.images.length <= 1) {
        return this;
      }
      _this = this;
      current = this.images[this.current].source;
      content = '';
      _ref = this.images;
      for (cid in _ref) {
        image = _ref[cid];
        selected = (current != null) === image.source ? ' selected' : '';
        content += templates.thumbnail.replace('{{selected}}', selected).replace('{{cid}}', cid).replace('{{thumbnail}}', image.thumbnail).replace('{{title}}', image.title ? ' title="' + image.title + '"' : '');
      }
      this.thumbnails.html(content).find('.sgl-thumbnail').click(function(event) {
        return _this.updateImage(parseInt($(this).attr('data-cid'), 10));
      });
      return this;
    };

    return Gallery;

  })();

  window.sglGallery = Gallery;

  if (jQuery && jQuery.fn) {
    jQuery.fn.gallery = function() {
      return new Gallery(this, arguments[0]);
    };
  }

}).call(this);
