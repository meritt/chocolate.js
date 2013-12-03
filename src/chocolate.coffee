choco = 'choco'
class_body     = "#{choco}-body"
class_error    = "#{choco}-error"
class_hover    = "#{choco}-hover"
class_item     = "#{choco}-item"
class_loading  = "#{choco}-loading"
class_selected = "#{choco}-selected"
class_show     = "#{choco}-show"


class Chocolate

  existActions = ['next', 'prev', 'close']

  env = {}

  isOpen = false
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

    template = templates.overlay
    template = template.replace '{{thumbnails}}', if @options.thumbnails then templates.thumbnails else ''

    @overlay = beforeend(document.body, template)[0]

    containers = ['leftside', 'rightside', 'slider']
    containers.push 'thumbnails' if @options.thumbnails

    for container in containers
      @[container] = @overlay.querySelector ".#{choco}-#{container}"

    @add images if images

    @length = @thumbnails.children.length

    addHandler @overlay, 'click', =>
      @close()
    , ".#{choco}-close"


    for container in ['overlay', 'leftside', 'rightside']
      prepareActionFor @, container

    instances.push @

    getEnv()

    @initTouch env




  close: ->
    isOpen = false
    opened = null
    if hasClass @overlay, class_show
      removeClass @overlay, class_show
      removeClass document.body, class_body
      removeClass @current.thumbnail, class_selected
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

    removeClass @current.thumbnail, class_selected if @current?

    thumb = item.thumbnail
    addClass thumb, class_selected

    offset = thumb.offsetLeft + thumb.offsetWidth / 2
    offset = env.w / 2 - offset

    if offset > 0
      offset = 0
    if offset < env.w - @dimensions.thumbWidth
      offset = env.w - @dimensions.thumbWidth

    translate @slider, env.shift * item.cid
    translate @thumbnails, offset

    @current = item

    if isHistory and updateHistory
      title = if item.title then item.title else item.hashbang
      pushState title, item.hashbang

    loading = hasClass item.slide, class_loading
    if loading
      loadImage item, (success) =>
        @updateSides item
    else
      @updateSides item

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
          orig:  image.getAttribute('data-src') or image.parentNode.getAttribute('href')
          title: image.getAttribute('data-title') or image.getAttribute('title') or ''
          thumb: image.getAttribute 'src'

      addImage @, object, image

    @




  updateDimensions: ->
    @dimensions =
      thumbWidth: @thumbnails.offsetWidth
    for i of @storage.images
      setSize @storage.images[i]




  updateSides: (item) ->
    if not item.size
      item.size = item.slide.querySelector(".#{choco}-slide-container").offsetWidth
    @leftside.style.width = (env.w - item.size) / 2 + 'px'
    @rightside.style.width = (env.w - item.size) / 2 + 'px'




  initTouch: -> true




  addImage = (chocolate, data, image) ->
    data = chocolate.storage.add data
    return unless data

    data.thumbnail = beforeend(chocolate.thumbnails, mustache templates['thumbnails-item'], data)[0]
    addHandler data.thumbnail, 'click', -> chocolate.select data

    data.slide = beforeend(chocolate.slider, mustache templates['slide'], data)[0]
    data.slide.classList.add class_loading

    data.img = data.slide.querySelector ".#{choco}-slide-image"

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

        popover = document.querySelector "[data-pid=\"#{data.cid}\"]"
        setStyle popover,
          'width':      "#{image.offsetWidth}px"
          'height':     "#{image.offsetHeight}px"
          'margin-top': "#{-1 * image.offsetHeight}px"

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
    return env unless needResize
    env =
      w: window.innerWidth or document.documentElement.clientWidth
      h: window.innerHeight or document.documentElement.clientHeight
    if isOpen
      slide = opened.slider.querySelector ".#{choco}-slide"
      return unless slide
      style = getStyle slide
      h = toInt(style 'height') -
          toInt(style 'padding-top') -
          toInt(style 'padding-bottom')
      w = toInt(style 'width') -
          toInt(style 'padding-left') -
          toInt(style 'padding-right')
      env.shift = toInt(style 'width') * -1
      env.s =
        w: w
        h: h
      needResize = false
    env




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
