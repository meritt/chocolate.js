(function() {
  var Gallery, counter, hideOverlay, isOverlay, showOverlay, template;

  template = '<div class="gallery-overlay">' + '<div class="gallery-image">' + '</div>' + '<div class="gallery-tumbnails">' + '</div>' + '</div>';

  counter = 0;

  Gallery = (function() {

    Gallery.prototype.images = {};

    /*
       Конструктор
    */

    function Gallery(options, images) {
      var _this = this;
      this.options = options != null ? options : {};
      this.overlay = $(template).appendTo('body');
      this.container = this.overlay.find('.gallery-image');
      this.tumbnails = this.overlay.find('.gallery-tumbnails');
      this.overlay.click(function(event) {
        if ($(event.target).hasClass('gallery-overlay')) {
          return hideOverlay(_this.overlay);
        }
      });
      $(document).bind('keyup', function(event) {
        if (isOverlay(_this.overlay)) {
          switch (event.keyCode) {
            case 27:
              return hideOverlay(_this.overlay);
            case 37:
              return console.log('left');
            case 39:
              return console.log('right');
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
      this.updateThumbnail(this.images[cid].source).updateImage(cid);
      showOverlay(this.overlay);
      return this;
    };

    /*
       Обновление изображения
    */

    Gallery.prototype.updateImage = function(cid) {
      var content, element, image;
      var _this = this;
      image = this.images[cid];
      if (!image.width || !image.height) {
        element = new Image();
        element.src = image.source;
        element.onload = function(event) {
          _this.images[image.index].width = element.width;
          _this.images[image.index].height = element.height;
          return _this.updateDimensions(element.width, element.height);
        };
      } else {
        this.updateDimensions(image.width, image.height);
      }
      content = image.title ? '<h1>' + image.title + '</h1>' : '';
      this.container.css('background-image', 'url(' + image.source + ')');
      this.container.html(content);
      return this;
    };

    Gallery.prototype.updateDimensions = function(width, height) {
      var left, top;
      left = '-' + parseInt(width / 2, 10) + 'px';
      top = '-' + (parseInt(height / 2, 10) + parseInt(this.tumbnails.height() / 2, 10)) + 'px';
      this.container.css({
        'width': width,
        'height': height,
        'margin-left': left,
        'margin-top': top
      });
      return this;
    };

    /*
       Обновление списка тумбнейлов
    */

    Gallery.prototype.updateThumbnail = function(current) {
      var content, _this;
      if (this.images.length === 0) return this;
      _this = this;
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

  showOverlay = function(overlay) {
    return overlay.css('display', 'block');
  };

  hideOverlay = function(overlay) {
    return overlay.css('display', 'none');
  };

  isOverlay = function(overlay) {
    return overlay.css('display') === 'block';
  };

  if (jQuery && jQuery.fn) {
    jQuery.fn.gallery = function() {
      return new Gallery(arguments[0], this);
    };
  }

}).call(this);
