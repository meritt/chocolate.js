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
    @overlay   = $(template).appendTo 'body'
    @container = @overlay.find '.gallery-image'
    @tumbnail  = @overlay.find '.gallery-tumbnails'

    @overlay.click (event) =>
      hideOverlay @overlay if $(event.target).hasClass 'gallery-overlay'

    $(document).bind 'keyup', (event) =>
      hideOverlay @overlay if event.keyCode is 27

    @add images if images

  ###
   Добавляем список изображений для работы в галереи
  ###
  add: (images) ->
    return if not images or images.length is 0

    $.each images, (index, image) =>
      image  = $ image
      source = image.parent().attr 'href'
      title  = image.attr 'title'

      if source
        cid = ++counter

        data =
          index:     cid
          element:   image
          source:    source
          title:     title
          thumbnail: image.attr 'src'

        image.addClass('gallery').attr('data-cid', cid).click (event) =>
          event.stopPropagation()
          event.preventDefault()

          @show data

        @images[cid] = data

  ###
   Показать изображение на большом экране
  ###
  show: (image) ->
    @updateThumbnail image.source
    @updateImage image
    showOverlay @overlay

  ###
   Обновление изображения
  ###
  updateImage: (image) ->
    if not image.width or not image.height
      element = new Image()
      element.src = image.source
      element.onload = (event) =>
        @images[image.index].width = element.width
        @images[image.index].height = element.height

        @updateDimensions element.width, element.height
    else
      @updateDimensions image.width, image.height

    content = if image.title then '<h1>' + image.title + '</h1>' else ''

    @container.css 'background-image', 'url(' + image.source + ')'
    @container.html content

  updateDimensions: (width, height) ->
    left = '-' + parseInt(width / 2, 10) + 'px'
    top  = '-' + (parseInt(height / 2, 10) + parseInt(@tumbnail.height() / 2, 10)) + 'px'
    @container.css 'width': width, 'height': height, 'margin-left': left, 'margin-top': top

  ###
   Обновление списка тумбнейлов
  ###
  updateThumbnail: (current) ->
    return if @images.length is 0

    _this = @

    content = ''
    $.each @images, (cid, image) ->
      selected = if current and current is image.source then ' class="selected"' else ''
      content += '<img src="' + image.thumbnail + '" data-gid="' + cid + '" width="140" height="140"' + selected + '>'

    @tumbnail.html content

    @tumbnail.find('img').click (event) ->
      image = $ @

      _this.tumbnail.find('img.selected').removeClass 'selected'
      image.addClass 'selected'

      _this.updateImage _this.images[image.data('gid')]


showOverlay = (overlay) -> overlay.css 'display', 'block'
hideOverlay = (overlay) -> overlay.css 'display', 'none'

if jQuery and jQuery.fn
  jQuery.fn.gallery = -> new Gallery arguments[0], @