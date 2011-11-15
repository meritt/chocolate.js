(function() {
  var Gallery, counter, hideOverlay, showOverlay, template;

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
      this.tumbnail = this.overlay.find('.gallery-tumbnails');
      this.overlay.click(function(event) {
        if ($(event.target).hasClass('gallery-overlay')) {
          return hideOverlay(_this.overlay);
        }
      });
      $(document).bind('keyup', function(event) {
        if (event.keyCode === 27) return hideOverlay(_this.overlay);
      });
      if (images) this.add(images);
    }

    /*
       Добавляем список изображений для работы в галереи
    */

    Gallery.prototype.add = function(images) {
      var _this = this;
      if (!images || images.length === 0) return;
      return $.each(images, function(index, image) {
        var cid, data, source, title;
        image = $(image);
        source = image.parent().attr('href');
        title = image.attr('title');
        if (source) {
          cid = ++counter;
          data = {
            index: cid,
            element: image,
            source: source,
            title: title,
            thumbnail: image.attr('src')
          };
          image.addClass('gallery').attr('data-cid', cid).click(function(event) {
            event.stopPropagation();
            event.preventDefault();
            return _this.show(data);
          });
          return _this.images[cid] = data;
        }
      });
    };

    /*
       Показать изображение на большом экране
    */

    Gallery.prototype.show = function(image) {
      this.updateThumbnail(image.source);
      this.updateImage(image);
      return showOverlay(this.overlay);
    };

    /*
       Обновление изображения
    */

    Gallery.prototype.updateImage = function(image) {
      var content, element;
      var _this = this;
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
      return this.container.html(content);
    };

    Gallery.prototype.updateDimensions = function(width, height) {
      var left;
      left = '-' + parseInt(width / 2, 10) + 'px';
      return this.container.css({
        'width': width,
        'height': height,
        'margin-left': left
      });
    };

    /*
       Обновление списка тумбнейлов
    */

    Gallery.prototype.updateThumbnail = function(current) {
      var content, _this;
      if (this.images.length === 0) return;
      _this = this;
      content = '';
      $.each(this.images, function(cid, image) {
        var selected;
        selected = current && current === image.source ? ' class="selected"' : '';
        return content += '<img src="' + image.thumbnail + '" data-gid="' + cid + '" width="140" height="140"' + selected + '>';
      });
      this.tumbnail.html(content);
      return this.tumbnail.find('img').click(function(event) {
        var image;
        image = $(this);
        _this.tumbnail.find('img.selected').removeClass('selected');
        image.addClass('selected');
        return _this.updateImage(_this.images[image.data('gid')]);
      });
    };

    return Gallery;

  })();

  showOverlay = function(overlay) {
    return overlay.css('display', 'block');
  };

  hideOverlay = function(overlay) {
    return overlay.css('display', 'none');
  };

  if (jQuery && jQuery.fn) {
    jQuery.fn.gallery = function() {
      return new Gallery(arguments[0], this);
    };
  }

}).call(this);
