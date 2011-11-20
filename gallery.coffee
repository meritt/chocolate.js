templates =
  overlay: '
<div class="sgl-overlay">
  <div class="sgl-leftside"></div>
  {{spinner}}
  <div class="sgl-container"></div>
  <div class="sgl-rightside"></div>
  {{thumbnails}}
  <div class="sgl-close"></div>
</div>
'
  spinner: '
<div class="sgl-spinner">
 <img src="../themes/default/images/spinner-bg.png" alt="">
 <img src="../themes/default/images/spinner-serenity.png" alt="">
</div>
'
  thumbnails: '
<div class="sgl-thumbnails"></div>
'
  thumbnail: '
<div class="sgl-thumbnail{{selected}}" data-cid="{{cid}}" style="background-image:url(\'{{thumbnail}}\')"{{title}}></div>
'
  header: '
<div class="sgl-header"><h1>{{title}}</h1></div>
'
  hover: '
<span class="sgl-item-hover" data-sglid="{{cid}}"></span>
'

counter = 0

nextAction  = 'next'
prevAction  = 'prev'
closeAction = 'close'

existActions = [nextAction, prevAction, closeAction]

isHistory = not not (window.history and history.pushState)

class Gallery
  images: {}
  current: null

  options:
    actions:
      overlay:    false
      leftside:   prevAction
      container:  nextAction
      rightside:  closeAction
    thumbnails: true

  ###
   Конструктор
  ###
  constructor: (images, options) ->
    @options = $.extend @options, options if options and typeof options is 'object'

    template = templates.overlay
    template = template.replace '{{spinner}}', templates.spinner
    template = template.replace '{{thumbnails}}', if @options.thumbnails then templates.thumbnails else ''

    @overlay = $(template).appendTo 'body'

    elements = ['container', 'spinner', 'leftside', 'rightside']
    elements.push 'thumbnails' if @options.thumbnails

    @[element] = @overlay.find '.sgl-' + element for element in elements

    @overlay.find('.sgl-close').click (event) => @close()

    @_prepareActionFor element for element in ['overlay', 'container', 'leftside', 'rightside']

    if isHistory
      $(window).bind 'popstate', (event) =>
        hash = window.location.hash
        cid  = if hash then parseInt hash.replace('#image', ''), 10 else 0
        if cid > 0
          if @current is null then @show cid else @updateImage cid, false

    $(window).bind 'keyup', (event) =>
      if @overlay.css('display') is 'block'
        switch event.keyCode
          when 27    # ESC
            @close()
          when 37    # Left arrow
            @prev()
          when 39    # Right arrow
            @next()

    @add images if images

  _prepareActionFor: (element) ->
    method = if @options.actions[element] in existActions then @options.actions[element] else false
    if method
      verify = @[element].attr 'class'
      @[element].click (event) => @[method]() if $(event.target).hasClass verify
    @

  ###
   Добавляем список изображений для работы в галереи
  ###
  add: (images) ->
    return @ if not images or images.length is 0

    for object in images
      image = null
      if object instanceof HTMLElement
        image  = $ object
        object =
          source:    image.attr('data-src') || image.parent().attr('href')
          title:     image.attr('data-title') || image.attr('title')
          thumbnail: image.attr('src')

      @_addToGallery object, image
    @

  _addToGallery: (data, image) ->
    return unless data.source

    cid = ++counter

    data.thumbnail = data.source unless data.thumbnail
    @images[cid] = data

    if image
      showFirstImage = (event, cid) =>
        event.stopPropagation()
        event.preventDefault()
        @show cid

      image.addClass('sgl-item').click (event) -> showFirstImage event, cid

      preload = new Image()
      preload.src = data.thumbnail
      preload.onload = (event) =>
        image.before templates.hover.replace '{{cid}}', cid
        $('[data-sglid=' + cid + ']').css(width: image.width(), height: image.height()).click (event) ->
          showFirstImage event, cid

  ###
   Показать изображение на большом экране
  ###
  show: (cid) ->
    cid = 1 unless cid?
    throw 'Image not found' unless @images[cid]?

    @current = cid if @current is null

    @createThumbnails() if @options.thumbnails
    @updateImage cid
    @overlay.css 'display', 'block'
    @

  close: ->
    @overlay.css 'display', 'none'
    @

  next: ->
    next = @current + 1
    @updateImage next if @images[next]?
    @

  prev: ->
    prev = @current - 1
    @updateImage prev if @images[prev]?
    @

  ###
   Обновление изображения
  ###
  updateImage: (cid, updateHistory = true) ->
    @current = cid

    if @options.thumbnails
      @thumbnails.find('.selected').removeClass 'selected'
      @thumbnails.find('[data-cid=' + cid + ']').addClass 'selected'

    if isHistory and updateHistory
      title = if @images[cid].title then 'Image: ' + @images[cid].title else null
      history.pushState null, title, '#image' + cid

    @getImageSize cid, (cid) ->
      image = @images[cid]

      @updateDimensions image.width, image.height

      @container.css 'background-image', 'url(' + image.source + ')'
      @container.html if image.title then templates.header.replace '{{title}}', image.title else ''
    @

  ###
   Обновление размеров блока с главным изображением
  ###
  getImageSize: (cid, after = ->) ->
    image = @images[cid]

    if not image.width or not image.height
      @spinner.css 'display', 'block'

      element     = new Image()
      element.src = image.source

      element.onload = (event) =>
        @spinner.css 'display', 'none'

        @images[cid].width  = element.width
        @images[cid].height = element.height

        delete element

        after.call @, cid
    else
      after.call @, cid

  ###
   Обновление размеров блока с главным изображением
  ###
  updateDimensions: (width, height) ->
    thumbnails = if @options.thumbnails then @thumbnails.height() else 0

    innerWidth   = window.innerWidth
    windowWidth  = innerWidth - 50
    innerHeight  = window.innerHeight
    windowHeight = innerHeight - 50 - thumbnails

    if width > windowWidth
      height = windowWidth * height / width
      width  = windowWidth

    if height > windowHeight
      width  = windowHeight * width / height
      height = windowHeight

    left = parseInt width / 2, 10
    top  = parseInt height / 2, 10
    top += parseInt thumbnails / 2, 10 if thumbnails > 0

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
    return @ if not @options.thumbnails or not @current or @images.length <= 1

    _this   = @
    current = @images[@current].source
    content = ''

    for cid, image of @images
      selected = if current? is image.source then ' selected' else ''
      content += templates.thumbnail.replace('{{selected}}', selected)
                                    .replace('{{cid}}', cid)
                                    .replace('{{thumbnail}}', image.thumbnail)
                                    .replace('{{title}}', if image.title then ' title="' + image.title + '"' else '')

    @thumbnails.html(content).find('.sgl-thumbnail').click (event) ->
      _this.updateImage parseInt $(@).attr('data-cid'), 10
    @

# Экспорт в глобальное пространство
window.sglGallery = Gallery

# Подключение к jQuery Plugins
if jQuery and jQuery.fn
  jQuery.fn.gallery = -> new Gallery @, arguments[0]