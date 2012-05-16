counter = 0

existActions = ['next', 'prev', 'close']

isHistory = not not (window.history and history.pushState)
isStorage = 'localStorage' of window and window['localStorage']?

class Chocolate
  images: {}
  length: 0

  current: null

  ###
   Конструктор
  ###
  constructor: (images, options = {}) ->
    if not document.querySelectorAll
      # throw "Please upgrade your browser to view chocolate"
      return false

    if not defaultOptions or not templates
      throw "You don't have defaultOptions or templates variables"
      return false

    @options = $.extend defaultOptions, options

    ###
     Подготовка шаблонов
    ###
    template = templates['overlay']
    template = template.replace '{{spinner}}', templates['spinner']
    template = template.replace '{{thumbnails}}', if @options.thumbnails then templates['thumbnails'] else ''

    @overlay = $(template).appendTo 'body'

    ###
     Получаем необходимые контейнеры
    ###
    containers = ['container', 'spinner', 'leftside', 'rightside', 'header']
    containers.push 'thumbnails' if @options.thumbnails

    @[container] = @overlay.find '.choco-' + container for container in containers

    ###
     Добавляем события по-умолчанию для контейнеров
    ###
    @overlay.find('.choco-close').on 'click', => @close()

    @_prepareActionFor container for container in ['overlay', 'container', 'leftside', 'rightside']

    $(window).on 'keyup', (event) =>
      if @overlay.hasClass 'choco-show'
        switch event.keyCode
          when 27    # ESC
            @close()
          when 37    # Left arrow
            @prev()
          when 39    # Right arrow
            @next()

    cssAnimationsSupport()

    ###
     Если можно использовать History API добавляем событие на отслеживание изменений в адресе
    ###
    isHistory = false if isHistory and not @options.history

    if isHistory
      onHistory = =>
        cid = @_getImageFromUri()

        if cid > 0 and cid isnt @current
          if @current is null
            @show cid
          else
            @open cid, false

      $(window).on 'load', -> onHistory()

      if 'onhashchange' of window
        $(window).on 'hashchange', -> onHistory()

    ###
     Получаем параметры отступов и другие неизменяемые размеры
    ###
    @dimensions = @_getInitialParams()

    ###
     Добавляем изображения для галереи
    ###
    @add images if images

  ###
   Добавляем список изображений для работы в галереи
  ###
  add: (images) ->
    return @ if not images or images.length is 0

    for object in images
      image     = null
      isElement = if typeof HTMLElement is "object" then object instanceof HTMLElement else typeof object is "object" and object.nodeType is 1 and typeof object.nodeName is "string"

      if isElement
        image  = $ object
        object =
          source:    image.attr('data-src') || image.parent().attr('href')
          title:     image.attr('data-title') || image.attr('title')
          thumbnail: image.attr('src')

      @_addToGallery object, image
    @

  ###
   Показать изображение на большом экране
  ###
  show: (cid) ->
    cid = @_getImageFromUri() unless cid?
    cid = 1 if cid <= 0
    throw 'Image not found' unless @images[cid]?

    @createThumbnails cid
    @overlay.addClass 'choco-show'

    @_hideLess() if @length is 1

    $(window).on 'resize', =>
      image = @images[@current]
      @updateDimensions image.width, image.height

    @open cid
    @

  close: ->
    if @overlay.hasClass 'choco-show'
      history.pushState null, null, '#' if isHistory

      if @options.thumbnails
        @thumbnails.html ''
        @overlay.find('.choco-thumbnails-toggle').off 'click'

      $(window).off 'resize'

      @current = null
      @overlay.removeClass 'choco-show'
    @

  open: (cid, updateHistory) ->
    if @current isnt cid
      @updateImage cid, updateHistory if @images[cid]?
    @

  next: ->
    next = @current + 1

    if @options.repeat
      next = 1 unless @images[next]?

    @updateImage next if @images[next]?
    @

  prev: ->
    prev = @current - 1

    if @options.repeat
      prev = counter unless @images[prev]?

    @updateImage prev if @images[prev]?
    @

  ###
   Обновление изображения
  ###
  updateImage: (cid, updateHistory = true) ->
    @current = cid

    @container.removeClass 'choco-show'
    @container.removeClass 'choco-error' if @container.hasClass 'choco-error'
    @header.removeClass 'choco-show' if @header.hasClass 'choco-show'
    @spinner.addClass 'choco-hide' if not @spinner.hasClass 'choco-hide'

    if isHistory and updateHistory
      title = if @images[cid].title then @images[cid].title else 'Image №' + cid
      history.pushState null, title, '#image' + cid

    @updateThumbnails()

    @getImageSize cid, (cid) ->
      @container.addClass 'choco-show'

      image = @images[cid]

      @updateDimensions image.width, image.height

      @container.css
        'background-image': 'url(' + image.source + ')'
        '-ms-filter': "\"progid:DXImageTransform.Microsoft.AlphaImageLoader(src='" + image.source + "', sizingMethod='scale')\""
      @header.html if image.title then templates['image-title'].replace '{{title}}', image.title else ''
    @

  ###
   Обновление размеров блока с главным изображением
  ###
  getImageSize: (cid, after = ->) ->
    image = @images[cid]

    fn = => after.call @, cid if cid is @current

    if not image.width or not image.height
      @spinner.removeClass 'choco-hide' if @spinner.hasClass 'choco-hide'

      element        = new Image()
      element.src    = image.source
      element.onload = =>
        if cid is @current
          @images[cid].width  = element.width
          @images[cid].height = element.height

          @spinner.addClass 'choco-hide' if not @spinner.hasClass 'choco-hide'

          fn()

      element.onerror = =>
        if cid is @current
          @spinner.addClass 'choco-hide' if not @spinner.hasClass 'choco-hide'
          @container.addClass 'choco-show choco-error'
          @updateDimensions @container.width(), @container.height()

    else
      fn()

  ###
   Обновление размеров блока с главным изображением
  ###
  updateDimensions: (width, height) ->
    title = not not @images[@current].title

    thumbnails = headerHeight = 0

    if @dimensions.thumbnails isnt false and not @thumbnails.hasClass('choco-hide')
      @dimensions.thumbnails = @thumbnails.height() if @dimensions.thumbnails is 0
      thumbnails = @dimensions.thumbnails

    headerHeight = @dimensions.header if title

    innerWidth   = window.innerWidth
    windowWidth  = innerWidth - @dimensions.horizontal
    innerHeight  = window.innerHeight
    windowHeight = innerHeight - @dimensions.vertical - thumbnails - headerHeight

    if width > windowWidth
      height = windowWidth * height / width
      width  = windowWidth

    if height > windowHeight
      width  = windowHeight * width / height
      height = windowHeight

    left = width / 2

    top  = height / 2
    top += thumbnails / 2   if thumbnails > 0
    top -= headerHeight / 2 if headerHeight > 0

    style =
      'width':  toInt(innerWidth / 2 - left) + 'px'
      'height': toInt(innerHeight) + 'px'

    @leftside.css  style
    @rightside.css style

    if title
      @header.addClass('choco-show').css
        'width':       toInt width
        'margin-left': '-' + toInt(left) + 'px'
        'margin-top':  '-' + toInt(top + headerHeight) + 'px'

    style =
      'width':       toInt width
      'height':      toInt height
      'margin-left': '-' + toInt(left) + 'px'
      'margin-top':  '-' + toInt(top) + 'px'

    @container.css style
    @spinner.css   style
    @

  ###
   Создание панели для тумбнейлов
  ###
  createThumbnails: (cid) ->
    return @ if not @options.thumbnails or not cid or @length <= 1

    _this   = @
    current = @images[cid]
    content = ''

    for cid, image of @images
      selected = if current.source? is image.source then ' selected' else ''
      template = templates['thumbnails-item']
      content += template.replace('{{selected}}', selected)
                         .replace('{{cid}}', cid)
                         .replace('{{thumbnail}}', image.thumbnail)
                         .replace('{{title}}', if image.title then ' title="' + image.title + '"' else '')

    @thumbnails.html(content).find('.choco-thumbnail').on 'click', ->
      _this.open toInt $(@).attr('data-cid')

    @overlay.find('.choco-thumbnails-toggle').on 'click', ->
      current = _this.images[_this.current]
      status  = _this.thumbnails.hasClass 'choco-hide'
      method  = if status then 'removeClass' else 'addClass'

      if isStorage
        localStorage.setItem 'choco-thumbnails', if status then 1 else 0

      _this.thumbnails[method] 'choco-hide'
      $(@)[method] 'choco-hide'

      _this.updateDimensions current.width, current.height if current

    if isStorage and not @thumbnails.hasClass 'choco-hide'
      status = localStorage.getItem('choco-thumbnails') || 1
      @overlay.find('.choco-thumbnails-toggle').trigger 'click' if toInt(status) is 0

    @

  ###
   Обновление тумбнейлов
  ###
  updateThumbnails: ->
    return @ if not @options.thumbnails or @length <= 1

    before = @thumbnails.find('.selected').removeClass('selected').attr 'data-cid'
    after  = @thumbnails.find('[data-cid="' + @current + '"]').addClass 'selected'

    if not @dimensions.thumbnail
      @dimensions.thumbnail = toInt @_outerWidth after

    width     = @thumbnails.width()
    element   = after.get(0).offsetLeft
    thumbnail = @dimensions.thumbnail
    container = @thumbnails.get(0).scrollLeft or 0

    if before
      offset = if @current > before then container + thumbnail else container - thumbnail
    else
      offset = element - (width / 2) + (thumbnail / 2)
      offset = 1 if offset <= 0

    if @options.repeat
      right = offset + width

      if right < element
        offset = thumbnail + element
      else if offset > element
        offset = 1

    @thumbnails.get(0).scrollLeft = offset
    @


  ###
   -- Private methods --
  ###


  ###
   Private method
  ###
  _addToGallery: (data, image) ->
    return unless data.source

    cid = ++counter

    data.thumbnail = data.source unless data.thumbnail
    @images[cid]   = data

    @length++

    if image
      showFirstImage = (event, cid) =>
        event.stopPropagation()
        event.preventDefault()
        @show cid

      image.addClass('choco-item').on 'click', (event) ->
        showFirstImage event, cid

      preload        = new Image()
      preload.src    = data.thumbnail
      preload.onload = ->
        image.after templates['image-hover'].replace '{{cid}}', cid

        popover = $('[data-pid="' + cid + '"]').css
          'width':      image.width()
          'height':     image.height()
          'margin-top': '-' + image.height() + 'px'

        image.on 'hover', (event) -> popover.toggleClass 'choco-hover'
        popover.on 'click', (event) -> showFirstImage event, cid

  ###
   Private method
  ###
  _prepareActionFor: (container) ->
    method = @options.actions[container] if @options.actions[container] in existActions

    if method
      verify = @[container].attr 'class'

      @[container].on 'click', (event) =>
        @[method]() if $(event.target).hasClass verify

      if @options.actions[container] is 'close'
        @[container].on 'mouseenter mouseleave', =>
          @overlay.find('.choco-close').toggleClass 'choco-hover'
    @

  ###
   Private method
  ###
  _getImageFromUri: ->
    hash = window.location.hash
    if hash then toInt hash.replace('#image', '') else 0

  ###
   Private method
  ###
  _getInitialParams: ->
    thumbnails = if not @options.thumbnails then false else @thumbnails.height()

    horizontal = toInt(@overlay.css('padding-left')) + toInt(@overlay.css('padding-right'))
    vertical   = toInt(@overlay.css('padding-top')) + toInt(@overlay.css('padding-bottom'))

    header = toInt @header.css('height')
    if header is 0
      header = 40
      @header.css 'height', header

    {horizontal, vertical, thumbnails, header}

  ###
   Private method
  ###
  _hideLess: ->
    @dimensions.thumbnails = false if @options.thumbnails
    @overlay.addClass 'choco-hideless'
    @

  ###
   Private method
  ###
  _outerWidth: (element) ->
    return element.outerWidth true if element.outerWidth?

    styles = [
      'margin-left'
      'margin-right'
      'padding-left'
      'padding-right'
      'border-left-width'
      'border-right-width'
    ]

    width = parseFloat element.css 'width'
    width += parseFloat element.css style for style in styles
    width


toInt = (string) -> parseInt string, 10

cssAnimationsSupport = ->
  return true if $('html').hasClass 'cssanimations'

  support = false
  element = document.createElement 'div'

  support = true if element.style.animationName

  prefixes = ['Webkit', 'Moz', 'O', 'ms']

  if support is false
    for prefix in prefixes
      if element.style[prefix + 'AnimationName'] isnt undefined
        support = true
        break

  $('html').addClass 'cssanimations' if support is true
  support

# Экспорт в глобальное пространство
window.chocolate = Chocolate

# Подключение к jQuery Plugins / Ender Plugins / Zepto Plugins
frameworks = ['jQuery', 'ender', 'Zepto']
for framework in frameworks
  if window[framework]?.fn
    window[framework].fn.chocolate = -> new Chocolate @, arguments[0]