(function() {
  var Gallery, counter, template;

  template = '<div class="gallery-overlay">' + '<div class="gallery-close"></div>' + '<div class="gallery-previous"></div>' + '<div class="gallery-image"></div>' + '<div class="gallery-tumbnails"></div>' + '</div>';

  counter = 0;

  Gallery = (function() {

    Gallery.prototype.images = {};

    Gallery.prototype.current = null;

    /*
       Конструктор
    */

    function Gallery(options, images) {
      var _this = this;
      this.options = options != null ? options : {};
      this.overlay = $(template).appendTo('body');
      this.container = this.overlay.find('.gallery-image');
      this.tumbnails = this.overlay.find('.gallery-tumbnails');
      this.previous = this.overlay.find('.gallery-previous');
      this.overlay.click(function(event) {
        if ($(event.target).hasClass('gallery-overlay')) return _this.close();
      });
      this.overlay.find('.gallery-close').click(function(event) {
        return _this.close();
      });
      this.previous.click(function(event) {
        return _this.prev();
      });
      this.container.click(function(event) {
        return _this.next();
      });
      $(document).bind('keyup', function(event) {
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

    /*
       Добавляем список изображений для работы в галереи
    */

    Gallery.prototype.add = function(images) {
      var _this = this;
      if (!images || images.length === 0) return this;
      $.each(images, function(index, image) {
        var cid, source, title;
        image = $(image);
        source = image.attr('data-src') || image.parent().attr('href') || null;
        title = image.attr('data-title') || image.attr('title') || null;
        if (source) {
          cid = ++counter;
          image.addClass('gallery').attr('data-cid', cid).click(function(event) {
            event.stopPropagation();
            event.preventDefault();
            return _this.show(cid);
          });
          return _this.images[cid] = {
            index: cid,
            element: image,
            source: source,
            title: title,
            thumbnail: image.attr('src')
          };
        }
      });
      return this;
    };

    /*
       Показать изображение на большом экране
    */

    Gallery.prototype.show = function(cid) {
      this.updateImage(cid).updateThumbnails();
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
      if (typeof this.images[next] !== 'undefined') this.updateImage(next);
      return this;
    };

    Gallery.prototype.prev = function() {
      var prev;
      prev = this.current - 1;
      if (typeof this.images[prev] !== 'undefined') this.updateImage(prev);
      return this;
    };

    /*
       Обновление изображения
    */

    Gallery.prototype.updateImage = function(cid) {
      this.current = cid;
      this.getImageSize(cid, function(cid) {
        var content, image;
        console.log('callback into getImageSize()');
        image = this.images[cid];
        this.updateDimensions(image.width, image.height);
        content = image.title ? '<div class="gallery-header"><h1>' + image.title + '</h1></div>' : '';
        this.container.css('background-image', 'url(' + image.source + ')');
        return this.container.html(content);
      });
      return this;
    };

    Gallery.prototype.getImageSize = function(cid, callback) {
      var element, image;
      var _this = this;
      if (callback == null) callback = function() {};
      image = this.images[cid];
      if (!image.width || !image.height) {
        element = new Image();
        element.src = image.source;
        element.onload = function(event) {
          _this.images[cid].width = element.width;
          _this.images[cid].height = element.height;
          return callback.call(_this, cid);
        };
      } else {
        callback.call(this, cid);
      }
      return this;
    };

    Gallery.prototype.updateDimensions = function(width, height) {
      var left, top, windowHeight, windowWidth;
      windowWidth = window.innerWidth - 50;
      windowHeight = window.innerHeight - 150;
      if (width > windowWidth) {
        height = (windowWidth * height) / width;
        width = windowWidth;
      }
      if (height > windowHeight) {
        width = (windowHeight * width) / height;
        height = windowHeight;
      }
      left = parseInt(width / 2, 10);
      top = parseInt(height / 2, 10) + parseInt(this.tumbnails.height() / 2, 10);
      this.previous.css({
        'width': (windowWidth / 2 - left) + 'px'
      });
      this.container.css({
        'width': width,
        'height': height,
        'margin-left': '-' + left + 'px',
        'margin-top': '-' + top + 'px'
      });
      return this;
    };

    /*
       Обновление списка тумбнейлов
    */

    Gallery.prototype.updateThumbnails = function() {
      var content, current, _this;
      if (this.images.length <= 1 || this.current === null) return this;
      _this = this;
      current = this.images[this.current].source;
      content = '';
      $.each(this.images, function(cid, image) {
        var selected;
        selected = current && current === image.source ? ' selected' : '';
        return content += '<div class="thumbnail' + selected + '" data-gid="' + cid + '" style="background-image:url(\'' + image.thumbnail + '\')"' + (image.title ? ' title="' + image.title + '"' : '') + '></div>';
      });
      this.tumbnails.html(content);
      this.tumbnails.find('div.thumbnail').click(function(event) {
        var image;
        image = $(this);
        _this.tumbnails.find('div.selected').removeClass('selected');
        image.addClass('selected');
        return _this.updateImage(image.data('gid'));
      });
      return this;
    };

    return Gallery;

  })();

  if (jQuery && jQuery.fn) {
    jQuery.fn.gallery = function() {
      return new Gallery(arguments[0], this);
    };
  }

}).call(this);
