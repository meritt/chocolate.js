template = '<div class="sgl-overlay">' +
           '<div class="sgl-leftside"></div>' +
           '<div class="sgl-spinner">' +
           ' <img src="../themes/default/images/spinner-bg.png" alt="">' +
           ' <img src="../themes/default/images/spinner-serenity.png" alt="">' +
           '</div>' +
           '<div class="sgl-image"></div>' +
           '<div class="sgl-rightside"></div>' +
           '<div class="sgl-tumbnails"></div>' +
           '<div class="sgl-close"></div>' +
           '</div>'

counter = 0

nextAction  = 'next'
prevAction  = 'prev'
closeAction = 'close'

class Gallery
  images: {}
  current: null

  options:
    overlay:    false
    leftside:   prevAction
    container:  nextAction
    rightside:  closeAction

  actions: [nextAction, prevAction, closeAction]

  ###
   Конструктор
  ###
  constructor: (images, options) ->
    @options = $.extend @options, options if options and typeof options is 'object'

    @overlay = $(template).appendTo 'body'

    @container = @overlay.find '.sgl-image'
    @spinner   = @overlay.find '.sgl-spinner'
    @leftside  = @overlay.find '.sgl-leftside'
    @rightside = @overlay.find '.sgl-rightside'
    @tumbnails = @overlay.find '.sgl-tumbnails'

    @overlay.find('.sgl-close').click (event) => @close()

    @prepareActionFor element for element in ['overlay', 'container', 'leftside', 'rightside']

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

  prepareActionFor: (element) ->
    method = if @options[element] in @actions then @options[element] else false
    if method
      verify = @[element].attr 'class'
      @[element].click (event) => @[method]() if $(event.target).hasClass verify
    @

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

        image.addClass('sgl-item').click (event) => @_initialShow event, cid

        @images[cid] =
          source:    source
          title:     title
          thumbnail: image.attr 'src'

        element = new Image()
        element.src = @images[cid].thumbnail
        element.onload = (event) =>
          image.before '<span class="sgl-item-hover" data-sglid="' + cid + '"></span>'
          $('span[data-sglid=' + cid + ']').css(width: image.width(), height: image.height()).click (event) =>
            @_initialShow event, cid
    @

  _initialShow: (event, cid) ->
    event.stopPropagation()
    event.preventDefault()
    @current = cid
    @show cid

  ###
   Показать изображение на большом экране
  ###
  show: (cid) ->
    @createThumbnails().updateImage cid
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

    @tumbnails.find('div.selected').removeClass 'selected'
    @tumbnails.find('div[data-cid=' + cid + ']').addClass 'selected'

    @getImageSize cid, (cid) ->
      image = @images[cid]

      @updateDimensions image.width, image.height

      content = if image.title then '<div class="sgl-header"><h1>' + image.title + '</h1></div>' else ''

      @container.css 'background-image', 'url(' + image.source + ')'
      @container.html content
    @

  ###
   Обновление размеров блока с главным изображением
  ###
  getImageSize: (cid, callback = ->) ->
    image = @images[cid]

    if not image.width or not image.height
      @spinner.css 'display', 'block'

      element     = new Image()
      element.src = image.source

      element.onload = (event) =>
        setTimeout (=>
          @spinner.css 'display', 'none'

          @images[cid].width  = element.width
          @images[cid].height = element.height

          delete element

          callback.call @, cid
        ), 500
    else
      callback.call @, cid
    @

  ###
   Обновление размеров блока с главным изображением
  ###
  updateDimensions: (width, height) ->
    innerWidth   = window.innerWidth
    windowWidth  = innerWidth - 50    # padding: 50px
    innerHeight  = window.innerHeight
    windowHeight = innerHeight - 150  # padding: 50px - 100px (tumbnails height)

    if width > windowWidth
      height = (windowWidth * height) / width
      width  = windowWidth

    if height > windowHeight
      width  = (windowHeight * width) / height
      height = windowHeight

    left = parseInt(width / 2, 10)
    top  = parseInt(height / 2, 10) + parseInt(@tumbnails.height() / 2, 10)

    style = 'width': (innerWidth / 2 - left) + 'px', 'height': innerHeight + 'px'

    @leftside.css  style
    @rightside.css style

    style = 'width': width, 'height': height, 'margin-left': '-' + left + 'px', 'margin-top': '-' + top + 'px'

    @container.css style
    @spinner.css   style
    @

  ###
   Создание панели для тумбнейлов
  ###
  createThumbnails: ->
    return @ if @images.length <= 1 or @current is null

    _this   = @
    current = @images[@current].source
    content = ''

    $.each @images, (cid, image) ->
      selected = if current and current is image.source then ' selected' else ''
      content += '<div class="sgl-thumbnail' + selected + '" data-cid="' + cid + '" style="background-image:url(\'' + image.thumbnail + '\')"' + (if image.title then ' title="' + image.title + '"' else '') + '></div>'

    @tumbnails.html content

    @tumbnails.find('div.sgl-thumbnail').click (event) ->
      _this.updateImage parseInt $(@).attr('data-cid'), 10
    @

# Подключение к jQuery Plugins
if jQuery and jQuery.fn
  jQuery.fn.gallery = -> new Gallery @, arguments[0]