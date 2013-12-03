existActions = ['next', 'prev', 'close']

class Chocolate

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
    template = template.replace '{{spinner}}', templates.spinner
    template = template.replace '{{thumbnails}}', if @options.thumbnails then templates.thumbnails else ''

    @overlay = beforeend(document.body, template)[0]

    containers = ['container', 'leftside', 'rightside', 'slider']
    containers.push 'thumbnails' if @options.thumbnails

    for container in containers
      @[container] = @overlay.querySelector ".choco-#{container}"

    @add images if images

    @length = @thumbnails.children.length

    addHandler @overlay, 'click', =>
      @close()
    , '.choco-close'


    for container in ['overlay', 'container', 'leftside', 'rightside']
      prepareActionFor @, container

    instances.push @

    @initTouch env




  close: ->
    isOpen = false
    opened = null
    if hasClass @overlay, 'choco-show'
      removeClass @overlay, 'choco-show'
      removeClass document.body, 'choco-body'
      removeClass @current.thumbnail, 'selected'
      @current = null
      pushState()
    @




  open: (cid, updateHistory) ->
    return if isOpen
    opened = @
    isOpen = true
    addClass @overlay, 'choco-show'
    addClass document.body, 'choco-body'
    @updateDimensions()
    @select cid, updateHistory
    @




  select: (item, updateHistory = true) ->

    if typeof item is 'number'
      item = @storage.get item

    return false unless item

    getEnv()

    @current.thumbnail.classList.remove 'selected' if @current?

    thumb = item.thumbnail
    addClass thumb, 'selected'

    offset = thumb.offsetLeft + thumb.offsetWidth / 2
    offset = env.w / 2 - offset

    if offset > 0
      offset = 0
    if offset < env.w - @dimensions.thumbWidth
      offset = env.w - @dimensions.thumbWidth

    translate @slider, env.shift * item.cid
    translate @thumbnails, offset

    @current = item

    unless item.size
      item.size = item.slide.querySelector('.choco-slide-container img').offsetWidth

    @leftside.style.width = (env.w - item.size) / 2 + 'px'
    @rightside.style.width = (env.w - item.size) / 2 + 'px'

    if isHistory and updateHistory
      title = if item.title then item.title else item.hashbang
      pushState title, item.hashbang

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




  initTouch: -> true




  addImage = (chocolate, data, image) ->
    data = chocolate.storage.add data
    return unless data

    data.slide = beforeend(chocolate.slider, mustache templates['slide'], data)[0]
    data.thumbnail = beforeend(chocolate.thumbnails, mustache templates['thumbnails-item'], data)[0]
    data.img = data.slide.querySelector '.choco-slide-image'

    addHandler data.thumbnail, 'click', -> chocolate.select data

    if image

      showFirstImage = (event, cid) =>
        event.stopPropagation()
        event.preventDefault()
        chocolate.open cid

      addClass image, 'choco-item'
      addHandler image, 'click', (event) ->
        showFirstImage event, data.cid

      preload = new Image()
      addHandler preload, 'load', ->
        data.w = preload.width
        data.h = preload.height
        image.insertAdjacentHTML 'afterend', mustache templates['image-hover'], data

        popover = document.querySelector "[data-pid=\"#{data.cid}\"]"
        setStyle popover,
          'width':      "#{image.offsetWidth}px"
          'height':     "#{image.offsetHeight}px"
          'margin-top': "#{-1 * image.offsetHeight}px"

        addHandler image, ['mouseenter', 'mouseleave'], ->
          toggleClass popover, 'choco-hover'

        addHandler popover, 'click', (event) ->
          showFirstImage event, data.cid

      addHandler preload, 'error', ->
        data.slide.classList.add 'choco-error'
        data.thumbnail.classList.add 'choco-error'

      preload.src = data.thumb

    data




  prepareActionFor = (chocolate, container) ->
    method = chocolate.options.actions[container] if chocolate.options.actions[container] in existActions

    if method
      verify = chocolate[container].classList[0]

      addHandler chocolate[container], 'click', (event) ->
        chocolate[method]() if hasClass event.target, verify

      if chocolate.options.actions[container] is 'close'
        addHandler chocolate[container], ['mouseenter', 'mouseleave'], ->
          toggleClass chocolate.overlay, 'choco-hover', '.choco-close'




  getEnv = () ->
    return env unless needResize
    if isOpen
      slide = opened.slider.querySelector '.choco-slide'
      env =
        w: window.innerWidth or document.documentElement.clientWidth
        h: window.innerHeight or document.documentElement.clientHeight
        s:
          w: slide.clientWidth
          h: slide.clientHeight
      env.shift = env.s.w * -1
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
    if isOpen && hasClass opened.overlay, 'choco-show'
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
