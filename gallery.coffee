template = '<div class="gallery-overlay">' +
           '<div class="gallery-image">' +
           '</div>' +
           '<div class="gallery-tumbnails">' +
           '</div>' +
           '</div>'

counter = 0

class Gallery
  images: {}

  ###
   Конструктор
  ###
  constructor: (@options = {}, images) ->
    self = @

    @overlay   = $(template).appendTo 'body'
    @container = @overlay.find '.gallery-image'
    @tumbnail  = @overlay.find '.gallery-tumbnails'

    @overlay.click (event) ->
      hideOverlay self.overlay if $(event.target).hasClass 'gallery-overlay'

    $(document).bind 'keyup', (event) ->
      hideOverlay self.overlay if event.keyCode is 27

    @add images if images

  ###
   Добавляем список изображений для работы в галереи
  ###
  add: (images) ->
    return if not images or images.length is 0

    self = @

    $.each images, (index, image) ->
      image  = $ image
      source = image.parent().attr 'href'

      if source
        cid = ++counter

        image.addClass('gallery').attr('data-cid', cid).click (event) ->
          event.stopPropagation()
          event.preventDefault()
          self.show $ @

        self.images[cid] =
          element:   image
          source:    source
          thumbnail: image.attr 'src'

  ###
   Показать изображение на большом экране
  ###
  show: (image) ->
    source = image.parent().attr 'href'

    if source
      @updateThumbnail source

      @updateImage source
      showOverlay @overlay

  ###
   Обновление изображения
  ###
  updateImage: (source) ->
    image = new Image()
    image.src = source
    image.onload = (event) => @updateDimensions image.width, image.height

    @container.css 'background-image', 'url(' + source + ')'

  updateDimensions: (width, height) ->
    left = '-' + parseInt(width / 2, 10) + 'px'
    @container.css 'width': width, 'height': height, 'margin-left': left

  ###
   Обновление списка тумбнейлов
  ###
  updateThumbnail: (current) ->
    return if @images.length is 0

    self = @

    content = ''
    $.each @images, (cid, image) ->
      selected = if current and current is image.source then ' class="selected"' else ''
      content += '<img src="' + image.thumbnail + '" data-gid="' + cid + '" width="140" height="140"' + selected + '>'

    @tumbnail.html content

    @tumbnail.find('img').click (event) ->
      image = $ @

      self.tumbnail.find('img.selected').removeClass 'selected'
      image.addClass 'selected'

      self.updateImage self.images[image.data('gid')].source


showOverlay = (overlay) -> overlay.css 'display', 'block'
hideOverlay = (overlay) -> overlay.css 'display', 'none'

if jQuery and jQuery.fn
  jQuery.fn.gallery = -> new Gallery arguments[0], @