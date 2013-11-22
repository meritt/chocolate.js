counter = 0

existActions = ['next', 'prev', 'close']

isHistory = not not (window.history and history.pushState)
isStorage = 'localStorage' of window and window['localStorage']?
isIE8     = document.documentMode? and document.documentMode is 8

getTarget = (element, selector) ->
  if selector?
    target = element.querySelector selector
  else
    target = element
  target

addHandler = (element, event, listener, selector) ->
  target = getTarget element, selector
  if target?
    unless event instanceof Array
      event = [event]
    for ev in event
      target.addEventListener ev, listener, false

addClass = (element, className, selector) ->
  target = getTarget element, selector
  if target.hasOwnProperty 'classList'
    target.classList.add className

removeClass = (element, className, selector) ->
  target = getTarget element, selector
  if target.hasOwnProperty 'classList'
    target.classList.remove className

toggleClass = (element, className, selector) ->
  target = getTarget element, selector
  if target.hasOwnProperty 'classList'
    target.classList.toggle className

hasClass = (element, className, selector) ->
  target = getTarget element, selector
  if target.hasOwnProperty 'classList'
    target.classList.contains className

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

    # jQuery
    @overlay = $(template).appendTo 'body'
    @overlay = @overlay[0]

    ###
     Получаем необходимые контейнеры
    ###
    containers = ['container', 'spinner', 'leftside', 'rightside', 'header']
    containers.push 'thumbnails' if @options.thumbnails

    for container in containers
      @[container] = @overlay.querySelector ".choco-#{container}"
    addClass @overlay, 'choco-ie8' if isIE8

    ###
     Добавляем события по-умолчанию для контейнеров
    ###
    addHandler @overlay, 'click', =>
      @close()
    , '.choco-close'

    @_prepareActionFor container for container in ['overlay', 'container', 'leftside', 'rightside']

    addHandler window, 'keyup', (event) =>
      if hasClass @overlay, 'choco-show'
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

      addHandler window, 'load', -> onHistory()

      if 'onhashchange' of window
        addHandler window, 'hashchange', -> onHistory()

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
      isElement = if typeof HTMLElement is 'object' then object instanceof HTMLElement else typeof object is 'object' and object.nodeType is 1 and typeof object.nodeName is 'string'

      if isElement
        #jquery
        image  = object
        object =
          source:    image.getAttribute('data-src') or image.parentNode.getAttribute('href')
          title:     image.getAttribute('data-title') or image.getAttribute('title')
          thumbnail: image.getAttribute 'src'

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
    addClass document.body, 'choco-body'
    addClass @overlay, 'choco-show'

    @_hideLess() if @length is 1

    addHandler window, 'resize', =>
      image = @images[@current]
      @updateDimensions image.width, image.height

    @open cid
    @

  close: ->
    if hasClass @overlay, 'choco-show'
      history.pushState null, null, '#' if isHistory

      if @options.thumbnails
        @thumbnails.html ''
        $(@overlay.querySelector('.choco-thumbnails-toggle')).off 'click'

      $(window).off 'resize'

      @current = null

      removeClass @overlay, 'choco-show'
      removeClass document.body, 'choco-body'
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

    removeClass @container, 'choco-show'
    removeClass @container, 'choco-error'

    removeClass @header, 'choco-show'
    addClass @spinner, 'choco-hide'

    if isHistory and updateHistory
      title = if @images[cid].title then @images[cid].title else @images[cid].hashbang
      history.pushState null, title, "##{@images[cid].hashbang}"

    @updateThumbnails()

    @getImageSize cid, (cid) ->
      addClass @container, 'choco-show'

      image = @images[cid]

      @updateDimensions image.width, image.height

      @container.css
        'background-image': 'url(' + image.source + ')'
        '-ms-filter': "\"progid:DXImageTransform.Microsoft.AlphaImageLoader(src='" + image.source + "',sizingMethod='scale')\""

      @header.html if image.title then templates['image-title'].replace '{{title}}', image.title else ''
    @

  ###
   Обновление размеров блока с главным изображением
  ###
  getImageSize: (cid, after = ->) ->
    image = @images[cid]

    fn = => after.call @, cid if cid is @current

    if not image.width or not image.height
      removeClass @spinner, 'choco-hide'

      element = new Image()

      element.onload = =>
        if cid is @current
          @images[cid].width  = element.width
          @images[cid].height = element.height

          addClass @spinner, 'choco-hide'

          fn()

      element.onerror = =>
        if cid is @current
          addClass @spinner, 'choco-hide'
          addClass @container, 'choco-show'
          addClass @container, 'choco-error'
          @updateDimensions $(@container).width(), $(@container).height()

      element.src = image.source

    else
      fn()

  ###
   Обновление размеров блока с главным изображением
  ###
  updateDimensions: (width, height) ->
    title = not not @images[@current].title

    thumbnails = headerHeight = 0

    if @dimensions.thumbnails isnt false and not hasClass @thumbnails, 'choco-hide'
      @dimensions.thumbnails = $(@thumbnails).height() if @dimensions.thumbnails is 0
      thumbnails = @dimensions.thumbnails

    headerHeight = @dimensions.header if title

    innerWidth   = window.innerWidth or document.documentElement.clientWidth
    windowWidth  = innerWidth - @dimensions.horizontal
    innerHeight  = window.innerHeight or document.documentElement.clientHeight
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
                         .replace('{{image}}', image.thumbnail)
                         .replace('{{title}}', if image.title then ' title="' + image.title + '"' else '')

    $(@thumbnails).html(content).find('.choco-thumbnail').each ->
      thumbnail = $ @
      image = thumbnail.attr 'data-image'

      thumbnail.on 'click', -> _this.open toInt thumbnail.attr 'data-cid'
      thumbnail.css 'background-image': 'url(' + image + ')'
      thumbnail.get(0).style['-ms-filter'] = "progid:DXImageTransform.Microsoft.AlphaImageLoader(src='" + image + "',sizingMethod='scale')"

    addHandler @overlay, 'click', ->
      current = _this.images[_this.current]
      status  = hasClass _this.thumbnails, 'choco-hide'
      method  = if status then 'removeClass' else 'addClass'

      if isStorage
        localStorage.setItem 'choco-thumbnails', if status then 1 else 0

      _this.thumbnails[method] 'choco-hide'
      $(@)[method] 'choco-hide'

      _this.updateDimensions current.width, current.height if current
    , '.choco-thumbnails-toggle'

    if isStorage and not hasClass @thumbnails, 'choco-hide'
      status = localStorage.getItem('choco-thumbnails') or 1
      $(@overlay).find('.choco-thumbnails-toggle').trigger 'click' if toInt(status) is 0

    @

  ###
   Обновление тумбнейлов
  ###
  updateThumbnails: ->
    return @ if not @options.thumbnails or @length <= 1

    before = $(@thumbnails).find('.selected').removeClass('selected').attr 'data-cid'
    after  = @thumbnails.querySelector "[data-cid='#{@current}']"
    addClass after, 'selected'

    if not @dimensions.thumbnail
      @dimensions.thumbnail = toInt @_outerWidth after

    width     = @thumbnails.width()
    element   = $(after).get(0).offsetLeft
    thumbnail = @dimensions.thumbnail
    container = $(@thumbnails).get(0).scrollLeft or 0

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

    fragments     = data.source.split '/'
    data.hashbang = fragments[fragments.length-1]

    @images[cid] = data

    @length++

    if image
      showFirstImage = (event, cid) =>
        event.stopPropagation()
        event.preventDefault()
        @show cid

      addClass image, 'choco-item'
      addHandler image, 'click', (event) ->
        showFirstImage event, cid

      preload = new Image()
      preload.onload = ->
        $(image).after templates['image-hover'].replace '{{cid}}', cid

        popover = $('[data-pid="' + cid + '"]').css
          'width':      $(image).width()
          'height':     $(image).height()
          'margin-top': '-' + $(image).height() + 'px'

        addHandler image, ['mouseenter', 'mouseleave'], ->
          toggleClass popover[0], 'choco-hover'

        addHandler popover[0], 'click', (event) ->
          showFirstImage event, cid

      preload.src = data.thumbnail

  ###
   Private method
  ###
  _prepareActionFor: (container) ->
    method = @options.actions[container] if @options.actions[container] in existActions

    if method
      verify = @[container].getAttribute 'class'

      addHandler @[container], 'click', (event) =>
        @[method]() if hasClass event.target, verify

      if @options.actions[container] is 'close'
        addHandler @[container], ['mouseenter', 'mouseleave'], =>
          toggleClass @overlay.querySelector('.choco-close'), 'choco-hover'
    @

  ###
   Private method
  ###
  _getImageFromUri: ->
    hash = window.location.hash
    cid  = 0

    for key, image of @images
      if "##{image.hashbang}" is hash
        cid = key
        break

    cid

  ###
   Private method
  ###
  _getInitialParams: ->
    thumbnails = if not @options.thumbnails then false else $(@thumbnails).height()

    horizontal = toInt($(@overlay).css('padding-left')) + toInt($(@overlay).css('padding-right'))
    vertical   = toInt($(@overlay).css('padding-top')) + toInt($(@overlay).css('padding-bottom'))

    header = toInt $(@header).css('height')
    if header is 0
      header = 40
      $(@header).css 'height', header

    {horizontal, vertical, thumbnails, header}

  ###
   Private method
  ###
  _hideLess: ->
    @dimensions.thumbnails = false if @options.thumbnails
    addClass @overlay, 'choco-hideless'
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
  return true if hasClass document.querySelector('html'), 'cssanimations'

  support = false
  element = document.createElement 'div'

  support = true if element.style.animationName

  prefixes = ['Webkit', 'Moz', 'O', 'ms']

  if support is false
    support = true for prefix in prefixes when element.style[prefix + 'AnimationName'] isnt undefined

  addClass document.querySelector('html'), 'cssanimations' if support is true
  support

# Экспорт в глобальное пространство
window.chocolate = Chocolate

# Подключение к jQuery Plugins / Ender Plugins / Zepto Plugins
frameworks = ['jQuery', 'ender', 'Zepto']
for framework in frameworks
  if window[framework]?.fn
    window[framework].fn.chocolate = -> new Chocolate @, arguments[0]
