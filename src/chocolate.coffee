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

    @overlay = beforeEnd document.body, template
    @slider = getTarget @overlay, ".#{choco}slider"

    startTouch @

    if isTouch
      @options.thumbnails = false
    else
      containers = ['leftside', 'rightside']

      if @options.thumbnails
        containers.push 'thumbnails'

      for container in containers
        @[container] = getTarget @overlay, ".#{choco}#{container}"

      if @options.thumbnails
        @thumbnailsToggle = getTarget @overlay, ".#{choco}thumbnails-toggle"

        addEvent @thumbnailsToggle, 'click', =>
          @toggleThumbnails()
          return
      else
        for container in ['overlay', 'leftside', 'rightside']
          addClass @[container], choco_no_thumbnails

      for container in ['overlay', 'leftside', 'rightside']
        prepareActionFor @, container

    if images
      @add images

    instances.push @

  close: ->
    setAnimation opened, false

    isOpen = false
    opened = null

    if hasClass @overlay, choco_show
      removeClass @overlay, choco_show
      removeClass document.body, choco_body

      if @options.thumbnails
        removeClass @current.thumbnail, choco_selected

      @current = null
      pushState()

    return @

  open: (cid, updateHistory) ->
    return @ if isOpen

    opened = @
    isOpen = true

    addClass @overlay, choco_show
    addClass document.body, choco_body

    showThumbnails = session.get()
    @toggleThumbnails showThumbnails if showThumbnails?

    @updateDimensions()
    @select cid, updateHistory

    setTimeout ->
      setAnimation opened
    , 0

    return @

  select: (item, updateHistory = true) ->
    if typeof item is 'number'
      item = @storage.get item

    return false unless item

    getEnv()
    translate @slider, env.shift * item.cid

    if @options.thumbnails
      if @current?
        removeClass @current.thumbnail, choco_selected

      thumb = item.thumbnail
      addClass thumb, choco_selected

      offset = (env.w / 2) - thumb.offsetLeft - (offsetWidth(thumb) / 2)
      offset = squeeze offset, 0, env.w - @dimensions.thumbWidth

      translate @thumbnails, offset

    if updateHistory
      pushState item.title ? item.hashbang, item.hashbang

    loading = hasClass item.slide, choco_loading
    if loading
      loadImage item, => @updateSides item
    else
      @updateSides item

    @current = item

    return true

  next: ->
    @select @storage.next @current
    return @

  prev: ->
    @select @storage.prev @current
    return @

  add: (images) ->
    return @ if not images or images.length is 0

    for object in images
      image = null

      if typeof HTMLElement is 'object'
        isElement = object instanceof HTMLElement
      else
        isElement = typeof object is 'object' and object.nodeType is 1 and typeof object.nodeName is 'string'

      if isElement
        image = object

        object =
          orig: getAttribute(image, 'data-src') or getAttribute(image.parentNode, 'href')
          title: getAttribute(image, 'data-title') or getAttribute(image, 'title') or getAttribute(image, 'alt') or getAttribute(image.parentNode, 'title')
          thumb: getAttribute(image, 'src')

      addImage @, object, image

    return @

  updateDimensions: ->
    if @options.thumbnails
      @dimensions = thumbWidth: offsetWidth @thumbnails

    for cid, image of @storage.images
      setSize image

    return

  updateSides: (item) ->
    return if isTouch

    if not item.size
      item.size = offsetWidth getTarget item.slide, ".#{choco}slide-container"

    s = "#{(env.w - item.size) / 2}px"

    setStyle @leftside, width: s
    setStyle @rightside, width: s

    return

  toggleThumbnails: (show) ->
    return if isTouch

    containers = ['leftside', 'rightside', 'overlay', 'thumbnailsToggle']

    if show?
      if show is '1'
        method = 'remove'
      else
        method = 'add'
    else
      if hasClass @thumbnails, choco_hide
        method = 'remove'
        show = true
      else
        method = 'add'
        show = false
      session.set show

    classList @thumbnails, choco_hide, null, method

    for container in containers
      classList @[container], choco_no_thumbnails, null, method

    return

  ###
    Private methods
  ###

  addImage = (chocolate, data, image) ->
    data = chocolate.storage.add data
    return unless data

    if chocolate.options.thumbnails
      template = mustache templates['thumbnails-item'], data
      data.thumbnail = beforeEnd chocolate.thumbnails, template

      addEvent data.thumbnail, 'click', ->
        chocolate.select data
        return

    template = mustache templates['slide'], data
    data.slide = beforeEnd chocolate.slider, template

    addClass data.slide, choco_loading

    data.img = getTarget data.slide, ".#{choco}slide-image"

    action = chocolate.options.actions.container
    if action in existActions
      addEvent data.slide, 'click', ->
        chocolate[action]()
        return
      , ".#{choco}slide-container"

    return unless image

    showFirstImage = (event, cid) ->
      stop event
      chocolate.open cid
      return

    addClass image, choco_item
    addEvent image, 'click', (event) ->
      showFirstImage event, data.cid
      return

    return if isTouch

    preload = new Image()

    addEvent preload, 'load', ->
      template = mustache templates['image-hover'], data
      image.insertAdjacentHTML 'afterend', template

      popover = getTarget document, '[data-pid="' + data.cid + '"]'
      setStyle popover,
        'width': "#{offsetWidth image}px"
        'height': "#{offsetHeight image}px"
        'margin-top': "-#{offsetHeight image}px"

      addEvent image, 'mouseenter', ->
        toggleClass popover, choco_hover
        return

      addEvent image, 'mouseleave', ->
        toggleClass popover, choco_hover
        return

      addEvent popover, 'click', (event) ->
        showFirstImage event, data.cid
        return

    preload.src = data.thumb

    return

  loadImage = (item, fn) ->
    image = new Image()

    addEvent image, 'load', ->
      item.img.src = @src
      item.w = image.width
      item.h = image.height

      removeClass item.slide, choco_loading
      setSize item

      fn true
      return

    addEvent image, 'error', ->
      removeClass item.slide, choco_loading

      addClass item.slide, choco_error
      addClass item.thumbnail, choco_error

      fn false
      return

    image.src = item.orig
    return

  prepareActionFor = (chocolate, container) ->
    action = chocolate.options.actions[container]
    return if action not in existActions

    verify = chocolate[container].classList[0]

    addEvent chocolate[container], 'click', (event) ->
      if hasClass event.target, verify
        chocolate[action]()

      return

    if action is 'close'
      addEvent chocolate[container], 'mouseenter', ->
        toggleClass chocolate.overlay, choco_hover, ".#{choco}close"
        return

      addEvent chocolate[container], 'mouseleave', ->
        toggleClass chocolate.overlay, choco_hover, ".#{choco}close"
        return

    return


  setSize = (item) ->
    return unless item.w > 0 and item.h > 0

    getEnv()

    s = scale item.w, item.h, env.s.w, env.s.h

    item.img.width = s[0]
    item.img.height = s[1]

    return

  addEvent window, 'resize', ->
    needResize = true

    if isOpen
      setAnimation opened, false

      opened.updateDimensions()
      opened.select opened.current

      setAnimation opened

    return

  setAnimation = (chocolate, enable = true) ->
    method = if enable then 'add' else 'remove'

    if chocolate.options.thumbnails
      classList chocolate.thumbnails, choco_animated, null, method

    classList chocolate.slider, choco_animated, null, method

  unless isTouch
    addEvent window, 'keydown', (event) ->
      if not isOpen or not hasClass opened.overlay, choco_show
        return

      switch event.keyCode
        when 27 # ESC
          opened.close()
        when 37 # Left arrow
          opened.prev()
        when 39 # Right arrow
          opened.next()

window.chocolate = Chocolate
