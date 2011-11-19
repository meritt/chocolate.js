templates =
  overlay: '
<div class="sgl-overlay">
  <div class="sgl-leftside"></div>
  {{spinner}}
  <div class="sgl-container"></div>
  <div class="sgl-rightside"></div>
  {{tumbnails}}
  <div class="sgl-close"></div>
</div>
'
  spinner: '
<div class="sgl-spinner">
 <img src="../themes/default/images/spinner-bg.png" alt="">
 <img src="../themes/default/images/spinner-serenity.png" alt="">
</div>
'
  tumbnails: '
<div class="sgl-tumbnails"></div>
'
  tumbnail: '
<div class="sgl-tumbnail{{selected}}" data-cid="{{cid}}" style="background-image:url(\'{{tumbnail}}\')"{{title}}></div>
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

class Gallery
  images: {}
  current: null

  options:
    actions:
      overlay:    false
      leftside:   prevAction
      container:  nextAction
      rightside:  closeAction
    tumbnails: true

  ###
   Конструктор
  ###
  constructor: (images, options) ->
    @options = $.extend @options, options if options and typeof options is 'object'

    template = templates.overlay
    template = template.replace '{{spinner}}', templates.spinner
    template = template.replace '{{tumbnails}}', if @options.tumbnails then templates.tumbnails else ''

    @overlay = $(template).appendTo 'body'

    elements = ['container', 'spinner', 'leftside', 'rightside']
    elements.push 'tumbnails' if @options.tumbnails

    @[element] = @overlay.find '.sgl-' + element for element in elements

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

    $.each images, (index, image) =>
      image  = $ image
      source = image.attr('data-src') || image.parent().attr('href') || null
      title  = image.attr('data-title') || image.attr('title') || null

      if source
        cid = ++counter

        image.addClass('sgl-item').click (event) => @_initialShow event, cid

        @images[cid] =
          source:   source
          title:    title
          tumbnail: image.attr 'src'

        element = new Image()
        element.src = @images[cid].tumbnail
        element.onload = (event) =>
          image.before templates.hover.replace '{{cid}}', cid
          $('[data-sglid=' + cid + ']').css(width: image.width(), height: image.height()).click (event) =>
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
    @createTumbnails() if @options.tumbnails
    @updateImage cid
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

    if @options.tumbnails
      @tumbnails.find('.selected').removeClass 'selected'
      @tumbnails.find('[data-cid=' + cid + ']').addClass 'selected'

    @getImageSize cid, (cid) ->
      image = @images[cid]

      @updateDimensions image.width, image.height

      @container.css 'background-image', 'url(' + image.source + ')'
      @container.html templates.header.replace '{{title}}', image.title if image.title
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
        setTimeout (=>
          @spinner.css 'display', 'none'

          @images[cid].width  = element.width
          @images[cid].height = element.height

          delete element

          after.call @, cid
        ), 500
    else
      after.call @, cid
    @

  ###
   Обновление размеров блока с главным изображением
  ###
  updateDimensions: (width, height) ->
    tumbnails = if @options.tumbnails then @tumbnails.height() else 0

    innerWidth   = window.innerWidth
    windowWidth  = innerWidth - 50               # padding: 50px
    innerHeight  = window.innerHeight
    windowHeight = innerHeight - 50 - tumbnails  # padding: 50px - 100px (tumbnails height)

    if width > windowWidth
      height = windowWidth * height / width
      width  = windowWidth

    if height > windowHeight
      width  = windowHeight * width / height
      height = windowHeight

    left = parseInt width / 2, 10
    top  = parseInt height / 2, 10
    top += parseInt tumbnails / 2, 10 if tumbnails > 0

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
  createTumbnails: ->
    return @ if not @options.tumbnails or not @current or @images.length <= 1

    _this   = @
    current = @images[@current].source
    content = ''

    $.each @images, (cid, image) ->
      selected = if current? is image.source then ' selected' else ''
      content += templates.tumbnail.replace('{{selected}}', selected)
                                   .replace('{{cid}}', cid)
                                   .replace('{{tumbnail}}', image.tumbnail)
                                   .replace('{{title}}', if image.title then ' title="' + image.title + '"' else '')

    @tumbnails.html content

    @tumbnails.find('.sgl-tumbnail').click (event) ->
      _this.updateImage parseInt $(@).attr('data-cid'), 10
    @

# Подключение к jQuery Plugins
if jQuery and jQuery.fn
  jQuery.fn.gallery = -> new Gallery @, arguments[0]