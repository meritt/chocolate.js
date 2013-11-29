existActions = ['next', 'prev', 'close']

isStorage = 'localStorage' of window and window['localStorage']?

class Chocolate

  env = {}

  constructor: (images, options = {}) ->

    if not document.querySelectorAll
      # throw "Please upgrade your browser to view chocolate"
      return false

    if not defaultOptions or not templates
      throw "You don't have defaultOptions or templates variables"
      return false

    @options = merge defaultOptions, options

    @storage = new ChocolateStorage @options.repeat

    template = templates['overlay']
    template = template.replace '{{spinner}}', templates['spinner']
    template = template.replace '{{thumbnails}}', if @options.thumbnails then templates['thumbnails'] else ''

    @overlay = beforeend(document.body, template)[0]

    containers = ['container', 'leftside', 'rightside', 'slider']
    containers.push 'thumbnails' if @options.thumbnails

    for container in containers
      @[container] = @overlay.querySelector ".choco-#{container}"

    @add images if images

    @length = @thumbnails.children.length

    getEnv()

    addHandler window, 'resize', =>
      getEnv()
      @select @current

    addHandler window, 'keyup', (event) =>
      if hasClass @overlay, 'choco-show'
        switch event.keyCode
          when 27    # ESC
            @close()
          when 37    # Left arrow
            @prev()
          when 39    # Right arrow
            @next()

    addHandler @overlay, 'click', =>
      @close()
    , '.choco-close'

    for container in ['overlay', 'container', 'leftside', 'rightside']
      prepareActionFor @, container



  close: ->
    if hasClass @overlay, 'choco-show'

      removeClass document.body, 'choco-body'
      removeClass @overlay, 'choco-show'

      # Repaint bug could be fixed with
      @overlay.offsetHeight

      pushState()

      @current = null

    @




  open: (cid, updateHistory) ->
    addClass @overlay, 'choco-show'
    addClass document.body, 'choco-body'
    getEnv() if env.shift is 0
    @updateDimensions()
    @select cid, updateHistory
    @




  select: (item, updateHistory = true) ->

    if typeof item is 'number'
      item = @storage.get item

    return false unless item
    return true if @current and @current.cid is item.cid

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
    if updateHistory
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
          title: image.getAttribute('data-title') or image.getAttribute('title')
          thumb: image.getAttribute 'src'

      addImage @, object, image

    @




  updateDimensions: ->
    @dimensions =
      thumbWidth: @thumbnails.offsetWidth




  addImage = (chocolate, data, image) ->
    data = chocolate.storage.add data
    return unless data

    data.slide = beforeend(chocolate.slider, mustache templates['slide'], data)[0]
    data.thumbnail = beforeend(chocolate.thumbnails, mustache templates['thumbnails-item'], data)[0]


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
      preload.onload = ->
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
    env.w = window.innerWidth or document.documentElement.clientWidth
    env.h = window.innerHeight or document.documentElement.clientHeight
    env.shift = document.querySelector('.choco-slider > *').offsetWidth * -1
    env




window.chocolate = Chocolate
