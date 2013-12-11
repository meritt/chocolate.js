choco = 'choco-'

choco_body          = choco + 'body'
choco_error         = choco + 'error'
choco_hide          = choco + 'hide'
choco_hover         = choco + 'hover'
choco_item          = choco + 'item'
choco_loading       = choco + 'loading'
choco_selected      = choco + 'selected'
choco_show          = choco + 'show'
choco_no_thumbnails = choco + 'no-thumbnails'

existActions = ['next', 'prev', 'close']

env = {}

isOpen = false
isTouch = null

needResize = true

instances = []
opened = null

class Chocolate
  constructor: (images, options = {}) ->
    if not document.querySelectorAll
      # throw "Please upgrade your browser to view chocolate"
      return false

    unless defaultOptions and templates
      throw "You don't have defaultOptions or templates variables"
      return false

    @options = merge defaultOptions, options

    @storage = new Storage @options.repeat

    template = templates.overlay.replace '{{thumbnails}}', if @options.thumbnails then templates.thumbnails else ''

    @overlay = beforeEnd(document.body, template)
    @slider = getTarget @overlay, ".#{choco}slider"

    isTouch = @initTouch getEnv()
    @options.thumbnails = false if isTouch

    unless isTouch

      containers = ['leftside', 'rightside']
      containers.push 'thumbnails' if @options.thumbnails

      for container in containers
        @[container] = getTarget @overlay, ".#{choco}#{container}"

      if @options.thumbnails
        @thumbnailsToggle = getTarget @overlay, ".#{choco}thumbnails-toggle"
        addEvent @thumbnailsToggle, 'click', =>
          @toggleThumbnails()
      else
        for container in ['overlay', 'leftside', 'rightside']
          addClass @[container], choco_no_thumbnails

      for container in ['overlay', 'leftside', 'rightside']
        prepareActionFor @, container

    @add images if images

    instances.push @




  close: ->
    isOpen = false
    opened = null
    if hasClass @overlay, choco_show
      removeClass @overlay, choco_show
      removeClass document.body, choco_body
      removeClass @current.thumbnail, choco_selected if @options.thumbnails
      @current = null
      pushState()
    @




  open: (cid, updateHistory) ->
    return if isOpen
    opened = @
    isOpen = true
    addClass @overlay, choco_show
    addClass document.body, choco_body
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

      removeClass @current.thumbnail, choco_selected if @current?

      thumb = item.thumbnail
      addClass thumb, choco_selected

      offset = env.w / 2 - thumb.offsetLeft - offsetWidth(thumb) / 2

      offset = squeeze offset, 0, env.w - @dimensions.thumbWidth
      translate @thumbnails, offset

    if updateHistory
      title = if item.title then item.title else item.hashbang
      pushState title, item.hashbang

    loading = hasClass item.slide, choco_loading
    if loading
      loadImage item, (success) =>
        @updateSides item
    else
      @updateSides item

    @current = item

    true




  next: ->
    @select @storage.next @current
    return @

  prev: ->
    @select @storage.prev @current
    return @




  add: (images) ->
    return @ if not images or images.length is 0

    for object in images
      image     = null
      isElement = if typeof HTMLElement is 'object' then object instanceof HTMLElement else typeof object is 'object' and object.nodeType is 1 and typeof object.nodeName is 'string'

      if isElement
        image  = object
        object =
          orig:  getAttribute(image, 'data-src') or getAttribute(image.parentNode, 'href')
          title: getAttribute(image, 'data-title') or getAttribute(image, 'title') or getAttribute(image, 'alt') or getAttribute(image.parentNode, 'title')
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
      item.size = offsetWidth getTarget item.slide, ".#{choco}slide-container"
    s = "#{(env.w - item.size) / 2}px"
    setStyle @leftside, width: s
    setStyle @rightside, width: s




  toggleThumbnails: ->
    return if isTouch
    containers = ['leftside', 'rightside', 'overlay', 'thumbnailsToggle']
    if hasClass @thumbnails, choco_hide
      removeClass @thumbnails, choco_hide
      for container in containers
        removeClass @[container], choco_no_thumbnails
    else
      addClass @thumbnails, choco_hide
      for container in containers
        addClass @[container], choco_no_thumbnails

  initTouch: ->
    return false

  ###
    Private methods
  ### 

  addImage = (chocolate, data, image) ->
    data = chocolate.storage.add data
    return unless data

    if chocolate.options.thumbnails
      data.thumbnail = beforeEnd(chocolate.thumbnails, mustache templates['thumbnails-item'], data)
      addEvent data.thumbnail, 'click', -> chocolate.select data

    data.slide = beforeEnd(chocolate.slider, mustache templates['slide'], data)
    addClass data.slide, choco_loading

    data.img = getTarget data.slide, ".#{choco}slide-image"

    method = chocolate.options.actions.container if chocolate.options.actions.container in existActions

    if method
      addEvent data.slide, 'click', ->
        chocolate[method]()
      , ".#{choco}slide-container"


    if image

      showFirstImage = (event, cid) =>
        event.stopPropagation()
        event.preventDefault()
        chocolate.open cid

      addClass image, choco_item
      addEvent image, 'click', (event) ->
        showFirstImage event, data.cid

      unless isTouch
        preload = new Image()
        addEvent preload, 'load', ->
          image.insertAdjacentHTML 'afterend', mustache templates['image-hover'], data

          popover = getTarget document, "[data-pid=\"#{data.cid}\"]"
          setStyle popover,
            'width':      "#{offsetWidth image}px"
            'height':     "#{offsetHeight image}px"
            'margin-top': "-#{offsetHeight image}px"

          addEvent image, 'mouseenter', -> toggleClass popover, choco_hover
          addEvent image, 'mouseleave', -> toggleClass popover, choco_hover

          addEvent popover, 'click', (event) ->
            showFirstImage event, data.cid

        preload.src = data.thumb

    data




  loadImage = (item, callback) ->
    img = new Image()

    addEvent img, 'load', ->
      item.img.src = @src
      removeClass item.slide, choco_loading
      item.w = img.width
      item.h = img.height
      setSize item

      callback true

    addEvent img, 'error', ->
      removeClass item.slide, choco_loading
      addClass item.slide, choco_error
      addClass item.thumbnail, choco_error

      callback false

    img.src = item.orig




  prepareActionFor = (chocolate, container) ->
    method = chocolate.options.actions[container] if chocolate.options.actions[container] in existActions

    if method
      verify = chocolate[container].classList[0]

      addEvent chocolate[container], 'click', (event) ->
        chocolate[method]() if hasClass event.target, verify

      if chocolate.options.actions[container] is 'close'
        addEvent chocolate[container], 'mouseenter', ->
          toggleClass chocolate.overlay, choco_hover, ".#{choco}close"

        addEvent chocolate[container], 'mouseleave', ->
          toggleClass chocolate.overlay, choco_hover, ".#{choco}close"




  getEnv = ->
    return env unless needResize

    env =
      w: window.innerWidth or document.documentElement.clientWidth
      h: window.innerHeight or document.documentElement.clientHeight

    if isOpen
      slide = getTarget opened.slider, ".#{choco}slide"
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

      env.shift = shift * -1
      env.s =
        w: w
        h: h

    env


  addEvent window, 'resize', ->
    needResize = true
    if isOpen
      opened.updateDimensions()
      opened.select opened.current

  addEvent window, 'keyup', (event) =>
    if isOpen && hasClass opened.overlay, choco_show
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

    setStyle item.slide, 'padding-top': "#{(env.s.h - s[1]) / 2}px"




window.chocolate = Chocolate
