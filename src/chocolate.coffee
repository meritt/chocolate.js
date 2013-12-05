choco = 'choco'
class_body     = "#{choco}-body"
class_error    = "#{choco}-error"
class_hide     = "#{choco}-hide"
class_hover    = "#{choco}-hover"
class_item     = "#{choco}-item"
class_loading  = "#{choco}-loading"
class_no_thumbnails = "#{choco}-no-thumbnails"
class_selected = "#{choco}-selected"
class_show     = "#{choco}-show"


class Chocolate

  existActions = ['next', 'prev', 'close']

  env = {}

  isOpen = false
  isTouch = null
  instances = []
  opened = null
  needResize = true

  constructor: (images, options = {}) ->

    if not document.querySelectorAll
      # throw "Please upgrade your browser to view chocolate"
      return false

    if not defaultOptions or not templates
      throw "You don't have defaultOptions or templates variables"
      return false

    @options = merge defaultOptions, options

    @storage = new ChocolateStorage @options.repeat

    template = templates.overlay.replace '{{thumbnails}}', if @options.thumbnails then templates.thumbnails else ''

    @overlay = beforeend(document.body, template)[0]
    @slider = getTarget @overlay, ".#{choco}-slider"

    getEnv()

    isTouch = @initTouch env
    @options.thumbnails = false if isTouch

    unless isTouch

      containers = ['leftside', 'rightside']
      containers.push 'thumbnails' if @options.thumbnails

      for container in containers
        @[container] = getTarget @overlay, ".#{choco}-#{container}"

      if @options.thumbnails
        @thumbnailsToggle = getTarget @overlay, ".#{choco}-thumbnails-toggle"
        addHandler @thumbnailsToggle, 'click', =>
          @toggleThumbnails()
      else
        for container in ['overlay', 'leftside', 'rightside']
          addClass @[container], class_no_thumbnails

      for container in ['overlay', 'leftside', 'rightside']
        prepareActionFor @, container

    @add images if images

    instances.push @




  close: ->
    isOpen = false
    opened = null
    if hasClass @overlay, class_show
      removeClass @overlay, class_show
      removeClass document.body, class_body
      removeClass @current.thumbnail, class_selected if @options.thumbnails
      @current = null
      pushState()
    @




  open: (cid, updateHistory) ->
    return if isOpen
    opened = @
    isOpen = true
    addClass @overlay, class_show
    addClass document.body, class_body
    @updateDimensions()
    @select cid, updateHistory
    @




  select: (item, updateHistory = true) ->

    if typeof item is 'number'
      item = @storage.get item

    return false unless item

    getEnv()

    translate @slider, env.shift * item.cid

    if @options.thumbnails

      removeClass @current.thumbnail, class_selected if @current?

      thumb = item.thumbnail
      addClass thumb, class_selected

      offset = env.w / 2 - thumb.offsetLeft - offsetWidth(thumb) / 2

      offset = squeeze offset, 0, env.w - @dimensions.thumbWidth
      translate @thumbnails, offset

    if isHistory and updateHistory
      title = if item.title then item.title else item.hashbang
      pushState title, item.hashbang

    loading = hasClass item.slide, class_loading
    if loading
      loadImage item, (success) =>
        @updateSides item
    else
      @updateSides item

    @current = item

    true




  next: ->
    @select @storage.next @current
    @




  prev: ->
    @select @storage.prev @current
    @




  add: (images) ->
    return @ if not images or images.length is 0

    for object in images
      image     = null
      isElement = if typeof HTMLElement is 'object' then object instanceof HTMLElement else typeof object is 'object' and object.nodeType is 1 and typeof object.nodeName is 'string'

      if isElement
        image  = object
        object =
          orig:  getAttribute(image, 'data-src') or getAttribute(image.parentNode, 'href')
          title: getAttribute(image, 'data-title') or getAttribute(image, 'title') or ''
          thumb: getAttribute(image, 'src')

      addImage @, object, image

    @




  updateDimensions: ->
    if @options.thumbnails
      @dimensions =
        thumbWidth: offsetWidth @thumbnails
    for i of @storage.images
      setSize @storage.images[i]




  updateSides: (item) ->
    return if isTouch
    if not item.size
      item.size = offsetWidth getTarget item.slide, ".#{choco}-slide-container"
    s = "#{(env.w - item.size) / 2}px"
    setStyle @leftside, width: s
    setStyle @rightside, width: s




  toggleThumbnails: ->
    return if isTouch
    containers = ['leftside', 'rightside', 'overlay', 'thumbnailsToggle']
    if hasClass @thumbnails, class_hide
      removeClass @thumbnails, class_hide
      for container in containers
        removeClass @[container], class_no_thumbnails
    else
      addClass @thumbnails, class_hide
      for container in containers
        addClass @[container], class_no_thumbnails




  initTouch: -> false




  addImage = (chocolate, data, image) ->
    data = chocolate.storage.add data
    return unless data

    if chocolate.options.thumbnails
      data.thumbnail = beforeend(chocolate.thumbnails, mustache templates['thumbnails-item'], data)[0]
      addHandler data.thumbnail, 'click', -> chocolate.select data

    data.slide = beforeend(chocolate.slider, mustache templates['slide'], data)[0]
    addClass data.slide, class_loading

    data.img = getTarget data.slide, ".#{choco}-slide-image"

    method = chocolate.options.actions.container if chocolate.options.actions.container in existActions

    if method
      addHandler data.slide, 'click', ->
        chocolate[method]()
      , ".#{choco}-slide-container"


    if image

      showFirstImage = (event, cid) =>
        event.stopPropagation()
        event.preventDefault()
        chocolate.open cid

      addClass image, class_item
      addHandler image, 'click', (event) ->
        showFirstImage event, data.cid

      preload = new Image()
      addHandler preload, 'load', ->
        image.insertAdjacentHTML 'afterend', mustache templates['image-hover'], data

        popover = getTarget document, "[data-pid=\"#{data.cid}\"]"
        setStyle popover,
          'width':      "#{offsetWidth image}px"
          'height':     "#{offsetHeight image}px"
          'margin-top': "-#{offsetHeight image}px"

        addHandler image, ['mouseenter', 'mouseleave'], ->
          toggleClass popover, class_hover

        addHandler popover, 'click', (event) ->
          showFirstImage event, data.cid

      preload.src = data.thumb

    data




  loadImage = (item, callback) ->
    img = new Image()

    addHandler img, 'load', ->
      item.img.src = @src
      removeClass item.slide, class_loading
      item.w = img.width
      item.h = img.height
      setSize item

      callback true

    addHandler img, 'error', ->
      removeClass item.slide, class_loading
      addClass item.slide, class_error
      addClass item.thumbnail, class_error

      callback false

    img.src = item.orig




  prepareActionFor = (chocolate, container) ->
    method = chocolate.options.actions[container] if chocolate.options.actions[container] in existActions

    if method
      verify = chocolate[container].classList[0]

      addHandler chocolate[container], 'click', (event) ->
        chocolate[method]() if hasClass event.target, verify

      if chocolate.options.actions[container] is 'close'
        addHandler chocolate[container], ['mouseenter', 'mouseleave'], ->
          toggleClass chocolate.overlay, class_hover, ".#{choco}-close"




  getEnv = ->
    return env unless needResize and isOpen

    slide = getTarget opened.slider, ".#{choco}-slide"
    return unless slide

    needResize = false

    style = getStyle slide
    shift = toInt style 'width'

    h = toInt(style 'height') -
        toInt(style 'padding-top') -
        toInt(style 'padding-bottom')
    w = shift -
        toInt(style 'padding-left') -
        toInt(style 'padding-right')

    env =
      w: window.innerWidth or document.documentElement.clientWidth
      h: window.innerHeight or document.documentElement.clientHeight
      shift: shift * -1
      s:
        w: w
        h: h




  getImageFromUri = () ->
    hash = window.location.hash
    return unless hash

    if isOpen
      item = opened.storage.search hash
      return opened.select item if item?

    for chocolate in instances
      item = chocolate.storage.search hash
      break if item?

    if item?
      opened.close() if isOpen
      chocolate.open item




  if isHistory
    onHistory = =>
      data = getImageFromUri()

    if 'onhashchange' of window
      addHandler window, 'hashchange', -> onHistory()




  addHandler window, 'load', ->
    onHistory()




  addHandler window, 'resize', ->
    needResize = true
    if isOpen
      opened.updateDimensions()
      opened.select opened.current




  addHandler window, 'keyup', (event) =>
    if isOpen && hasClass opened.overlay, class_show
      switch event.keyCode
        when 27 # ESC
          opened.close()
        when 37 # Left arrow
          opened.prev()
        when 39 # Right arrow
          opened.next()




  setSize = (item) ->
    return if not (item.w > 0 and item.h > 0)
    getEnv()

    s = scale item.w, item.h, env.s.w, env.s.h

    item.img.width = s[0]
    item.img.height = s[1]




window.chocolate = Chocolate
