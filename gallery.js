(function() {
  var Gallery, counter, template;

  template = '<div class="sgl-overlay">' + '<div class="sgl-close"></div>' + '<div class="sgl-previous"></div>' + '<div class="sgl-spinner">' + ' <img src="../themes/default/images/spinner-bg.png" alt="">' + ' <img src="../themes/default/images/spinner-serenity.png" alt="">' + '</div>' + '<div class="sgl-image"></div>' + '<div class="sgl-tumbnails"></div>' + '</div>';

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
      this.container = this.overlay.find('.sgl-image');
      this.tumbnails = this.overlay.find('.sgl-tumbnails');
      this.previous = this.overlay.find('.sgl-previous');
      this.spinner = this.overlay.find('.sgl-spinner');
      this.overlay.click(function(event) {
        if ($(event.target).hasClass('sgl-overlay')) return _this.close();
      });
      this.overlay.find('.sgl-close').click(function(event) {
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
          image.addClass('sgl-item').attr('data-cid', cid).click(function(event) {
            event.stopPropagation();
            event.preventDefault();
            _this.current = cid;
            return _this.show(cid);
          });
          return _this.images[cid] = {
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
      this.createThumbnails().updateImage(cid);
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
      this.tumbnails.find('div.selected').removeClass('selected');
      this.tumbnails.find('div[data-gid=' + cid + ']').addClass('selected');
      this.getImageSize(cid, function(cid) {
        var content, image;
        image = this.images[cid];
        this.updateDimensions(image.width, image.height);
        content = image.title ? '<div class="sgl-header"><h1>' + image.title + '</h1></div>' : '';
        this.container.css('background-image', 'url(' + image.source + ')');
        return this.container.html(content);
      });
      return this;
    };

    /*
       Обновление размеров блока с главным изображением
    */

    Gallery.prototype.getImageSize = function(cid, callback) {
      var element, image;
      var _this = this;
      if (callback == null) callback = function() {};
      image = this.images[cid];
      if (!image.width || !image.height) {
        this.spinner.css('display', 'block');
        element = new Image();
        element.src = image.source;
        element.onload = function(event) {
          return setTimeout((function() {
            _this.spinner.css('display', 'none');
            _this.images[cid].width = element.width;
            _this.images[cid].height = element.height;
            delete element;
            return callback.call(_this, cid);
          }), 500);
        };
      } else {
        callback.call(this, cid);
      }
      return this;
    };

    /*
       Обновление размеров блока с главным изображением
    */

    Gallery.prototype.updateDimensions = function(width, height) {
      var innerHeight, left, style, top, windowHeight, windowWidth;
      windowWidth = window.innerWidth - 50;
      innerHeight = window.innerHeight;
      windowHeight = innerHeight - 150;
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
      style = {
        'width': width,
        'height': height,
        'margin-left': '-' + left + 'px',
        'margin-top': '-' + top + 'px'
      };
      this.previous.css({
        'width': (windowWidth / 2 - left) + 'px',
        'height': innerHeight + 'px'
      });
      this.container.css(style);
      this.spinner.css(style);
      return this;
    };

    /*
       Создание панели для тумбнейлов
    */

    Gallery.prototype.createThumbnails = function() {
      var content, current, _this;
      if (this.images.length <= 1 || this.current === null) return this;
      _this = this;
      current = this.images[this.current].source;
      content = '';
      $.each(this.images, function(cid, image) {
        var selected;
        selected = current && current === image.source ? ' selected' : '';
        return content += '<div class="sgl-thumbnail' + selected + '" data-gid="' + cid + '" style="background-image:url(\'' + image.thumbnail + '\')"' + (image.title ? ' title="' + image.title + '"' : '') + '></div>';
      });
      this.tumbnails.html(content);
      this.tumbnails.find('div.sgl-thumbnail').click(function(event) {
        return _this.updateImage(parseInt($(this).attr('data-gid'), 10));
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
