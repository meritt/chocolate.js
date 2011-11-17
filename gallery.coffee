template = '<div class="gallery-overlay">' +
           '<div class="gallery-close"></div>' +
           '<div class="gallery-previous"></div>' +
           '<div class="gallery-image"></div>' +
           '<div class="gallery-tumbnails"></div>' +
           '</div>'

counter = 0

class Gallery
  images: {}
  current: null

  ###
   Конструктор
  ###
  constructor: (@options = {}, images) ->
    @overlay   = $(template).appendTo 'body'
    @container = @overlay.find '.gallery-image'
    @tumbnails = @overlay.find '.gallery-tumbnails'
    @previous  = @overlay.find '.gallery-previous'

    @overlay.click (event) => @close() if $(event.target).hasClass 'gallery-overlay'
    @overlay.find('.gallery-close').click (event) => @close()

    @previous.click (event) => @prev()
    @container.click (event) => @next()

    $(document).bind 'keyup', (event) =>
      if @overlay.css('display') is 'block'
        switch event.keyCode
          when 27    # ESC
            @close()
          when 37    # Left arrow
            @prev()
          when 39    # Right arrow
            @next()

    @add images if images

  ###
   Добавляем список изображений для работы в галереи
  ###
  add: (images) ->
    return @ if not images or images.length is 0

    $.each images, (index, image) =>
      image  = $ image
      source = image.attr('data-src') || image.parent().attr('href') || null
      title  = image.attr('data-title') || image.attr('title') || null

      if source
        cid = ++counter

        image.addClass('gallery').attr('data-cid', cid).click (event) =>
          event.stopPropagation()
          event.preventDefault()
          @show cid

        @images[cid] =
          index:     cid
          element:   image
          source:    source
          title:     title
          thumbnail: image.attr('src')
    @

  ###
   Показать изображение на большом экране
  ###
  show: (cid) ->
    @updateImage(cid).updateThumbnails()
    @overlay.css 'display', 'block'
    @

  close: ->
    @overlay.css 'display', 'none'
    @

  next: ->
    next = @current + 1
    @updateImage next if typeof @images[next] isnt 'undefined'
    @

  prev: ->
    prev = @current - 1
    @updateImage prev if typeof @images[prev] isnt 'undefined'
    @

  ###
   Обновление изображения
  ###
  updateImage: (cid) ->
    @current = cid

    @getImageSize cid, (cid) ->
      console.log 'callback into getImageSize()'

      image = @images[cid]

      @updateDimensions image.width, image.height

      content = if image.title then '<div class="gallery-header"><h1>' + image.title + '</h1></div>' else ''

      @container.css 'background-image', 'url(' + image.source + ')'
      @container.html content
    @

  getImageSize: (cid, callback = ->) ->
    image = @images[cid]

    if not image.width or not image.height
      element     = new Image()
      element.src = image.source

      element.onload = (event) =>
        @images[cid].width  = element.width
        @images[cid].height = element.height

        callback.call @, cid
    else
      callback.call @, cid
    @

  updateDimensions: (width, height) ->
    windowWidth  = window.innerWidth - 50   # padding: 50px
    windowHeight = window.innerHeight - 150 # padding: 50px - 100px (tumbnails height)

    if width > windowWidth
      height = (windowWidth * height) / width
      width  = windowWidth

    if height > windowHeight
      width  = (windowHeight * width) / height
      height = windowHeight

    left = parseInt(width / 2, 10)
    top  = parseInt(height / 2, 10) + parseInt(@tumbnails.height() / 2, 10)

    @previous.css  'width': (windowWidth / 2 - left) + 'px'
    @container.css 'width': width, 'height': height, 'margin-left': '-' + left + 'px', 'margin-top': '-' + top + 'px'
    @

  ###
   Обновление списка тумбнейлов
  ###
  updateThumbnails: ->
    return @ if @images.length <= 1 or @current is null

    _this   = @
    current = @images[@current].source
    content = ''

    $.each @images, (cid, image) ->
      selected = if current and current is image.source then ' selected' else ''
      content += '<div class="thumbnail' + selected + '" data-gid="' + cid + '" style="background-image:url(\'' + image.thumbnail + '\')"' + (if image.title then ' title="' + image.title + '"' else '') + '></div>'

    @tumbnails.html content

    @tumbnails.find('div.thumbnail').click (event) ->
      image = $ @

      _this.tumbnails.find('div.selected').removeClass 'selected'
      image.addClass 'selected'

      _this.updateImage image.data('gid')
    @


if jQuery and jQuery.fn
  jQuery.fn.gallery = -> new Gallery arguments[0], @