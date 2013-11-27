counter = 0

existActions = ['next', 'prev', 'close']

isHistory = not not (window.history and history.pushState)
isStorage = 'localStorage' of window and window['localStorage']?
isIE8     = document.documentMode? and document.documentMode is 8

class Chocolate
  images: {}
  length: 0

  current: null
  env = {}

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

    @options = merge defaultOptions, options

    ###
     Подготовка шаблонов
    ###
    template = templates['overlay']
    template = template.replace '{{spinner}}', templates['spinner']
    template = template.replace '{{thumbnails}}', if @options.thumbnails then templates['thumbnails'] else ''

    document.body.insertAdjacentHTML 'beforeend', template
    @overlay = document.body.lastChild

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

    addHandler window, 'resize', @_onResize

    @open cid
    @

  close: ->
    if hasClass @overlay, 'choco-show'
      history.pushState null, null, '#' if isHistory

      if @options.thumbnails
        @thumbnails.innerHTML = ''
        removeHandler @overlay, 'click', @_toggleThumbnails, '.choco-thumbnails-toggle'

      removeHandler window, 'resize', @_onResize

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

      setStyle @container, "background-image": "url(#{image.source})"

      @header.innerHTML = if image.title then templates['image-title'].replace '{{title}}', image.title else ''
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

      addHandler element, 'load', =>
        if cid is @current
          @images[cid].width  = element.width
          @images[cid].height = element.height

          addClass @spinner, 'choco-hide'

          fn()

      addHandler element, 'error', =>
        if cid is @current
          addClass @spinner, 'choco-hide'
          addClass @container, 'choco-show'
          addClass @container, 'choco-error'
          @updateDimensions @container.offsetWidth, @container.offsetHeight

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
      @dimensions.thumbnails = @thumbnails.offsetHeight if @dimensions.thumbnails is 0
      thumbnails = @dimensions.thumbnails

    headerHeight = @dimensions.header if title

    windowWidth  = env.w - @dimensions.horizontal
    windowHeight = env.h - @dimensions.vertical - thumbnails - headerHeight

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
      'width':  "#{toInt(innerWidth / 2 - left)}px"

    setStyle @leftside,  style
    setStyle @rightside, style

    if title
      addClass @header, 'choco-show'
      setStyle @header,
        'width':       "#{toInt width}px"
        'margin-left': "-#{toInt left}px"
        'margin-top':  "-#{toInt(top + headerHeight)}px"

    style =
      'width':       "#{toInt width}px"
      'height':      "#{toInt height}px"
      'margin-left': "-#{toInt left}px"
      'margin-top':  "-#{toInt top}px"

    setStyle @container, style
    setStyle @spinner, style
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
                         .replace('{{title}}', if image.title then " title=\"#{image.title}\"" else '')

    @thumbnails.innerHTML = content
    [].forEach.call @thumbnails.querySelectorAll('.choco-thumbnail'), (thumbnail) ->
      image = thumbnail.getAttribute 'data-image'

      addHandler thumbnail, 'click', -> _this.open toInt @getAttribute 'data-cid'
      setStyle thumbnail, "background-image": "url(#{image})"

    addHandler @overlay, 'click', @_toggleThumbnails, '.choco-thumbnails-toggle'

    if isStorage and not hasClass @thumbnails, 'choco-hide'
      status = localStorage.getItem('choco-thumbnails') or 1
      @overlay.querySelector('.choco-thumbnails-toggle').click() if toInt(status) is 0

    @

  ###
   Обновление тумбнейлов
  ###
  updateThumbnails: ->
    return @ if not @options.thumbnails or @length <= 1

    before = @thumbnails.querySelector '.selected'
    if before?
      removeClass before, 'selected'
      before = before.getAttribute 'data-cid'
    after  = @thumbnails.querySelector "[data-cid='#{@current}']"
    addClass after, 'selected'

    if not @dimensions.thumbnail
      @dimensions.thumbnail = toInt @_outerWidth after

    offset = after.offsetLeft + after.offsetWidth / 2
    thumb = @thumbnails.offsetWidth
    offset = env.w / 2 - offset
    if offset > 0
      offset = 0
    if thumb + offset < env.w
      offset = env.w - thumb
    console.log offset

    translate @thumbnails, offset
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
        console.log 'click'
        showFirstImage event, cid

      preload = new Image()
      preload.onload = ->
        image.insertAdjacentHTML 'afterend', templates['image-hover'].replace '{{cid}}', cid

        popover = document.querySelector "[data-pid=\"#{cid}\"]"
        setStyle popover,
          'width':      "#{image.offsetWidth}px"
          'height':     "#{image.offsetHeight}px"
          'margin-top': "#{-1 * image.offsetHeight}px"

        addHandler image, ['mouseenter', 'mouseleave'], ->
          toggleClass popover, 'choco-hover'

        addHandler popover, 'click', (event) ->
          showFirstImage event, cid

      preload.src = data.thumbnail

  ###
   Private method
  ###
  _prepareActionFor: (container) ->
    method = @options.actions[container] if @options.actions[container] in existActions

    if method
      verify = @[container].classList[0]

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
    getWindowSize()
    thumbnails = if not @options.thumbnails then false else @thumbnails.offsetHeight

    css = getStyle @overlay
    horizontal = toInt(css 'padding-left') + toInt(css 'padding-right')
    vertical   = toInt(css 'padding-top') + toInt(css 'padding-bottom')

    header = toInt getStyle(@header)('height')
    if header is 0
      header = 40
      setStyle @header, "height": "#{header}px"

    {horizontal, vertical, thumbnails, header}

  ###
   Private method
  ###
  _hideLess: ->
    @dimensions.thumbnails = false if @options.thumbnails
    addClass @overlay, 'choco-hideless'
    @

  _onResize: (event) =>
    getWindowSize()
    image = @images[@current]
    @updateDimensions image.width, image.height

  _toggleThumbnails: (event) =>
    current = @images[@current]
    status  = hasClass @thumbnails, 'choco-hide'

    if isStorage
      localStorage.setItem 'choco-thumbnails', if status then 1 else 0

    if status
      removeClass @thumbnails, 'choco-hide'
      removeClass event.target, 'choco-hide'
    else
      addClass @thumbnails, 'choco-hide'
      addClass event.target, 'choco-hide'

    @updateDimensions current.width, current.height if current


  ###
   Private method
  ###
  _outerWidth: (element) ->
    return element.outerWidth true if element.outerWidth?

    css = getStyle element

    styles = [
      'margin-left'
      'margin-right'
      'padding-left'
      'padding-right'
      'border-left-width'
      'border-right-width'
    ]

    width = parseFloat css 'width'
    width += parseFloat css style for style in styles
    width

  getWindowSize = () ->
    env.w = window.innerWidth or document.documentElement.clientWidth
    env.h = window.innerHeight or document.documentElement.clientHeight

merge = (o1, o2) ->
  for own key, value of o2
    if value instanceof Object
      o1[key] = merge o1[key], value
    else
      o1[key] = value
  o1

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

removeHandler = (element, event, listener, selector) ->
  target = getTarget element, selector
  if target?
    unless event instanceof Array
      event = [event]
    for ev in event
      target.removeEventListener ev, listener, false

hasClassList = (element, selector) ->
  target = getTarget element, selector
  if target? and target.hasOwnProperty 'classList'
    return target.classList
  else
    return false

addClass = (element, className, selector) ->
  list = hasClassList element, selector
  list.add className if list

removeClass = (element, className, selector) ->
  list = hasClassList element, selector
  list.remove className if list

toggleClass = (element, className, selector) ->
  list = hasClassList element, selector
  list.toggle className if list

hasClass = (element, className, selector) ->
  list = hasClassList element, selector
  list.contains className if list

getStyle = (element) ->
  style = getComputedStyle element
  return (property) -> style.getPropertyValue.call style, property

setStyle = (element, styles) ->
  properties = Object.keys styles
  properties.forEach (property) ->
    prop = property.replace /-([a-z])/g, (g) -> g[1].toUpperCase()
    element.style[prop] = styles[property]

translate = do ->
  property = false
  has3d = false

  element = document.createElement 'div'
  property = 'transform' if element.style.transform

  prefixes = ['Webkit', 'Moz', 'O', 'ms']

  if property is false
    for prefix in prefixes when element.style["#{prefix}Transform"] isnt undefined
      property = "#{prefix}Transform"

  has3d = true if prefix is 'Webkit'
  if property isnt false
    (element, s) ->
      if has3d
        s = "translate3d(#{s}px, 0, 0)"
      else
        s = "translateX(#{s}px)"
      element.style[property] = s



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

window.chocolate = Chocolate
