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
      var self;
      this.options = options != null ? options : {};
      self = this;
      this.overlay = $(template).appendTo('body');
      this.container = this.overlay.find('.gallery-image');
      this.tumbnail = this.overlay.find('.gallery-tumbnails');
      this.overlay.click(function(event) {
        if ($(event.target).hasClass('gallery-overlay')) {
          return hideOverlay(self.overlay);
        }
      });
      $(document).bind('keyup', function(event) {
        if (event.keyCode === 27) return hideOverlay(self.overlay);
      });
      if (images) this.add(images);
    }

    /*
       Добавляем список изображений для работы в галереи
    */

    Gallery.prototype.add = function(images) {
      var self;
      if (!images || images.length === 0) return;
      self = this;
      return $.each(images, function(index, image) {
        var cid, source;
        image = $(image);
        source = image.parent().attr('href');
        if (source) {
          cid = ++counter;
          image.addClass('gallery').attr('data-cid', cid).click(function(event) {
            event.stopPropagation();
            event.preventDefault();
            return self.show($(this));
          });
          return self.images[cid] = {
            element: image,
            source: source,
            thumbnail: image.attr('src')
          };
        }
      });
    };

    /*
       Показать изображение на большом экране
    */

    Gallery.prototype.show = function(image) {
      var source;
      source = image.parent().attr('href');
      if (source) {
        this.updateThumbnail(source);
        this.updateImage(source);
        return showOverlay(this.overlay);
      }
    };

    /*
       Обновление изображения
    */

    Gallery.prototype.updateImage = function(source) {
      var image;
      var _this = this;
      image = new Image();
      image.src = source;
      image.onload = function(event) {
        return _this.updateDimensions(image.width, image.height);
      };
      return this.container.css('background-image', 'url(' + source + ')');
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
      var content, self;
      if (this.images.length === 0) return;
      self = this;
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
        self.tumbnail.find('img.selected').removeClass('selected');
        image.addClass('selected');
        return self.updateImage(self.images[image.data('gid')].source);
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
