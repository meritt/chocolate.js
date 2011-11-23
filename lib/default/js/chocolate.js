(function() {
  var Chocolate, counter, defaultOptions, existActions, isHistory, templates, updateBasedir;
  var __hasProp = Object.prototype.hasOwnProperty, __indexOf = Array.prototype.indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (__hasProp.call(this, i) && this[i] === item) return i; } return -1; };

  defaultOptions = {"actions":{"overlay":false,"leftside":"prev","container":"next","rightside":"close"},"thumbnails":true,"history":true,"repeat":true,"basedir":"/chocolate"};

  templates = {
  "image-hover": "<span class=\"choco-item-hover\" data-sglid=\"{{cid}}\"></span>",

  "overlay": "
    <div class=\"choco-overlay\">
      <div class=\"choco-leftside\"></div>
      {{spinner}}
      <div class=\"choco-container\"></div>
      <div class=\"choco-rightside\"></div>
      {{thumbnails}}
      <div class=\"choco-close\">&times;</div>
    </div>
  ",

  "spinner": "
    <div class=\"choco-spinner\">
     <img src=\"{{basedir}}/images/spinner-bg.png\" alt=\"\">
     <img src=\"{{basedir}}/images/spinner-serenity.png\" alt=\"\">
    </div>
  ",

  "image-title": "<div class=\"choco-header\"><h1>{{title}}</h1></div>",

  "thumbnails": "<div class=\"choco-thumbnails-toggle\"></div><div class=\"choco-thumbnails\"></div>",

  "thumbnails-item": "<div class=\"choco-thumbnail{{selected}}\" data-cid=\"{{cid}}\" style=\"background-image:url('{{thumbnail}}')\"{{title}}></div>"
};

  counter = 0;

  existActions = ['next', 'prev', 'close'];

  isHistory = !!(window.history && history.pushState);

  updateBasedir = function(template, basedir) {
    return template.replace(/\{\{basedir\}\}/g, basedir);
  };

  Chocolate = (function() {

    Chocolate.prototype.images = {};

    Chocolate.prototype.current = null;

    /*
       Конструктор
    */

    function Chocolate(images, options) {
      var element, elements, template, _i, _j, _len, _len2, _ref;
      var _this = this;
      if (options == null) options = {};
      if (!defaultOptions || !templates) {
        throw "You don't have defaultOptions or templates variables";
      }
      this.options = $.extend(defaultOptions, options);
      if (!this.options.history) isHistory = false;
      template = templates['overlay'];
      template = template.replace('{{spinner}}', templates['spinner']);
      template = template.replace('{{thumbnails}}', this.options.thumbnails ? templates['thumbnails'] : '');
      template = updateBasedir(template, this.options.basedir);
      this.overlay = $(template).appendTo('body');
      elements = ['container', 'spinner', 'leftside', 'rightside'];
      if (this.options.thumbnails) elements.push('thumbnails');
      for (_i = 0, _len = elements.length; _i < _len; _i++) {
        element = elements[_i];
        this[element] = this.overlay.find('.choco-' + element);
      }
      this.overlay.find('.choco-close').click(function(event) {
        return _this.close();
      });
      _ref = ['overlay', 'container', 'leftside', 'rightside'];
      for (_j = 0, _len2 = _ref.length; _j < _len2; _j++) {
        element = _ref[_j];
        this._prepareActionFor(element);
      }
      if (isHistory) {
        $(window).bind('popstate', function(event) {
          var cid;
          cid = _this.getImageFromUri();
          if (cid > 0 && cid !== _this.current) {
            if (_this.current === null) {
              return _this.show(cid);
            } else {
              return _this.updateImage(cid, false);
            }
          }
        });
      }
      $(window).bind('keyup', function(event) {
        if (_this.overlay.hasClass('show')) {
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

    Chocolate.prototype._prepareActionFor = function(element) {
      var method, verify, _ref;
      var _this = this;
      method = (_ref = this.options.actions[element], __indexOf.call(existActions, _ref) >= 0) ? this.options.actions[element] : false;
      if (method) {
        verify = this[element].attr('class');
        this[element].click(function(event) {
          if ($(event.target).hasClass(verify)) return _this[method]();
        });
        if (this.options.actions[element] === 'close') {
          this[element].bind('mouseenter mouseleave', function(event) {
            return _this._hoverCloseButton();
          });
        }
      }
      return this;
    };

    Chocolate.prototype._hoverCloseButton = function() {
      return this.overlay.find('.choco-close').toggleClass('hover');
    };

    Chocolate.prototype.getImageFromUri = function() {
      var hash;
      hash = window.location.hash;
      if (hash) {
        return parseInt(hash.replace('#image', ''), 10);
      } else {
        return 0;
      }
    };

    /*
       Добавляем список изображений для работы в галереи
    */

    Chocolate.prototype.add = function(images) {
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

    Chocolate.prototype._addToGallery = function(data, image) {
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
        image.addClass('choco-item').click(function(event) {
          return showFirstImage(event, cid);
        });
        preload = new Image();
        preload.src = data.thumbnail;
        return preload.onload = function(event) {
          image.before(templates['image-hover'].replace('{{cid}}', cid));
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

    Chocolate.prototype.show = function(cid) {
      if (cid == null) cid = this.getImageFromUri();
      if (cid <= 0) cid = 1;
      if (this.images[cid] == null) throw 'Image not found';
      if (this.current === null) this.current = cid;
      if (this.options.thumbnails) this.createThumbnails();
      this.updateImage(cid);
      this.overlay.addClass('show');
      return this;
    };

    Chocolate.prototype.close = function() {
      this.overlay.removeClass('show');
      return this;
    };

    Chocolate.prototype.next = function() {
      var next;
      next = this.current + 1;
      if (this.options.repeat) if (this.images[next] == null) next = 1;
      if (this.images[next] != null) this.updateImage(next);
      return this;
    };

    Chocolate.prototype.prev = function() {
      var prev;
      prev = this.current - 1;
      if (this.options.repeat) if (this.images[prev] == null) prev = counter;
      if (this.images[prev] != null) this.updateImage(prev);
      return this;
    };

    /*
       Обновление изображения
    */

    Chocolate.prototype.updateImage = function(cid, updateHistory) {
      var title;
      if (updateHistory == null) updateHistory = true;
      this.current = cid;
      this.container.removeClass('show');
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
        this.container.addClass('show');
        image = this.images[cid];
        this.updateDimensions(image.width, image.height);
        this.container.css('background-image', 'url(' + image.source + ')');
        return this.container.html(image.title ? templates['image-title'].replace('{{title}}', image.title) : '');
      });
      return this;
    };

    /*
       Обновление размеров блока с главным изображением
    */

    Chocolate.prototype.getImageSize = function(cid, after) {
      var element, image;
      var _this = this;
      if (after == null) after = function() {};
      image = this.images[cid];
      if (!image.width || !image.height) {
        this.spinner.removeClass('hide');
        element = new Image();
        element.src = image.source;
        return element.onload = function(event) {
          _this.spinner.addClass('hide');
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

    Chocolate.prototype.updateDimensions = function(width, height) {
      var innerHeight, innerWidth, left, style, thumbnails, top, windowHeight, windowWidth;
      thumbnails = !this.options.thumbnails || this.thumbnails.css('display') === 'none' ? 0 : this.thumbnails.height();
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

    Chocolate.prototype.createThumbnails = function() {
      var cid, content, current, image, selected, template, _ref, _this;
      if (!this.options.thumbnails || !this.current || this.images.length <= 1) {
        return this;
      }
      _this = this;
      current = this.images[this.current];
      content = '';
      _ref = this.images;
      for (cid in _ref) {
        image = _ref[cid];
        selected = (current.source != null) === image.source ? ' selected' : '';
        template = templates['thumbnails-item'];
        content += template.replace('{{selected}}', selected).replace('{{cid}}', cid).replace('{{thumbnail}}', image.thumbnail).replace('{{title}}', image.title ? ' title="' + image.title + '"' : '');
      }
      this.thumbnails.html(content).find('.choco-thumbnail').click(function(event) {
        return _this.updateImage(parseInt($(this).attr('data-cid'), 10));
      });
      this.overlay.find('.choco-thumbnails-toggle').click(function(event) {
        var method;
        method = _this.thumbnails.hasClass('hide') ? 'removeClass' : 'addClass';
        _this.thumbnails[method]('hide');
        $(this)[method]('hide');
        return _this.updateDimensions(current.width, current.height);
      });
      return this;
    };

    return Chocolate;

  })();

  window.chocolate = Chocolate;

  if (jQuery && jQuery.fn) {
    jQuery.fn.chocolate = function() {
      return new Chocolate(this, arguments[0]);
    };
  }

}).call(this);
