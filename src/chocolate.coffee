counter = 0

existActions = ['next', 'prev', 'close']

isHistory = not not (window.history and history.pushState)
# isFullscreen = document.webkitRequestFullScreen || document.mozRequestFullScreen
# test = document.getElementById 'choco-overlay'
# if test.webkitRequestFullScreen
#   test.webkitRequestFullScreen()
# else
#   test.mozRequestFullScreen()

class Chocolate
  images: {}
  length: 0

  current: null

  ###
   Конструктор
  ###
  constructor: (images, options = {}) ->
    throw "You don't have defaultOptions or templates variables" if not defaultOptions or not templates

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
    @overlay.find('.choco-close').click => @close()

    @_prepareActionFor container for container in ['overlay', 'container', 'leftside', 'rightside']

    $(window).bind 'keyup', (event) =>
      if @overlay.hasClass 'show'
        switch event.keyCode
          when 27    # ESC
            @close()
          when 37    # Left arrow
            @prev()
          when 39    # Right arrow
            @next()

    ###
     Если можно использовать History API добавляем событие на отслеживание изменений в адресе
    ###
    isHistory = false if isHistory and not @options.history

    if isHistory
      $(window).bind 'popstate', =>
        cid = @_getImageFromUri()

        if cid > 0 and cid isnt @current
          if @current is null
            @show cid
          else
            @open cid, false

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
      image = null
      if object instanceof HTMLElement
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

    @current = cid if @current is null

    @createThumbnails() if @options.thumbnails
    @overlay.addClass 'show'

    @open cid
    @

  close: ->
    if @overlay.hasClass 'show'
      history.pushState null, null, '#' if isHistory

      @current = null
      @thumbnails.html '' if @options.thumbnails
      @overlay.removeClass 'show'
    @

  open: (cid) ->
    @updateImage cid if @images[cid]?
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

    @container.removeClass 'show'
    @header.removeClass 'show' if @header.hasClass 'show'

    if isHistory and updateHistory
      title = if @images[cid].title then 'Image: ' + @images[cid].title else null
      history.pushState null, title, '#image' + cid

    @updateThumbnails() if @options.thumbnails

    @getImageSize cid, (cid) ->
      @container.addClass 'show'

      image = @images[cid]

      @updateDimensions image.width, image.height

      @container.css 'background-image', 'url(' + image.source + ')'
      @header.html if image.title then templates['image-title'].replace '{{title}}', image.title else ''
    @

  ###
   Обновление размеров блока с главным изображением
  ###
  getImageSize: (cid, after = ->) ->
    image = @images[cid]

    fn = => after.call @, cid if cid is @current

    if not image.width or not image.height
      @spinner.removeClass 'hide'

      element        = new Image()
      element.src    = image.source
      element.onload = =>
        @spinner.addClass 'hide'

        @images[cid].width  = element.width
        @images[cid].height = element.height

        delete element

        fn()
    else
      fn()

  ###
   Обновление размеров блока с главным изображением
  ###
  updateDimensions: (width, height) ->
    title = not not @images[@current].title

    thumbnails = headerHeight = 0

    if @dimensions.thumbnails isnt false and not @thumbnails.hasClass('hide')
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

    left = toInt width / 2

    top  = height / 2
    top += thumbnails / 2   if thumbnails > 0
    top -= headerHeight / 2 if headerHeight > 0

    style =
      'width':  toInt(innerWidth / 2 - left) + 'px'
      'height': innerHeight + 'px'

    @leftside.css  style
    @rightside.css style

    if title
      @header.addClass('show').css
        'width':       width
        'margin-left': '-' + left + 'px'
        'margin-top':  '-' + toInt(top + headerHeight) + 'px'

    style =
      'width':       width
      'height':      height
      'margin-left': '-' + left + 'px'
      'margin-top':  '-' + toInt(top) + 'px'

    @container.css style
    @spinner.css   style
    @

  ###
   Создание панели для тумбнейлов
  ###
  createThumbnails: ->
    return @ if not @options.thumbnails or not @current or @length <= 1

    _this   = @
    current = @images[@current]
    content = ''

    for cid, image of @images
      selected = if current.source? is image.source then ' selected' else ''
      template = templates['thumbnails-item']
      content += template.replace('{{selected}}', selected)
                         .replace('{{cid}}', cid)
                         .replace('{{thumbnail}}', image.thumbnail)
                         .replace('{{title}}', if image.title then ' title="' + image.title + '"' else '')

    @thumbnails.html(content).find('.choco-thumbnail').click ->
      _this.open toInt $(@).attr('data-cid')

    @overlay.find('.choco-thumbnails-toggle').click ->
      current = _this.images[_this.current]
      method  = if _this.thumbnails.hasClass 'hide' then 'removeClass' else 'addClass'

      _this.thumbnails[method] 'hide'
      $(@)[method] 'hide'

      _this.updateDimensions current.width, current.height

    @

  ###
   Обновление тумбнейлов
  ###
  updateThumbnails: ->
    @thumbnails.find('.selected').removeClass 'selected'

    thumbnail = @thumbnails.find('[data-cid=' + @current + ']').addClass 'selected'

    width = thumbnail.outerWidth() + toInt thumbnail.css('margin-right')
    left  = thumbnail.offset().left

    if @thumbnails.width() < width + left
      offset = @thumbnails.scrollLeft() + width
      offset = width + left if @thumbnails.width() + offset < width + left

    else if @thumbnails.scrollLeft() > left
      offset = if left < width then 0 else @thumbnails.scrollLeft() - width

    @thumbnails.scrollLeft offset if offset > 0
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

      image.addClass('choco-item').click (event) ->
        showFirstImage event, cid

      preload        = new Image()
      preload.src    = data.thumbnail
      preload.onload = ->
        image.after templates['image-hover'].replace '{{cid}}', cid

        popover = $('[data-pid=' + cid + ']').css
          'width':      image.width()
          'height':     image.height()
          'margin-top': '-' + image.height() + 'px'

        popover.click (event) -> showFirstImage event, cid

  ###
   Private method
  ###
  _prepareActionFor: (container) ->
    method = @options.actions[container] if @options.actions[container] in existActions

    if method
      verify = @[container].attr 'class'

      @[container].click (event) =>
        @[method]() if $(event.target).hasClass verify

      if @options.actions[container] is 'close'
        @[container].bind 'mouseenter mouseleave', =>
          @overlay.find('.choco-close').toggleClass 'hover'
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


toInt = (string) -> parseInt string, 10

# Экспорт в глобальное пространство
window.chocolate = Chocolate

# Подключение к jQuery Plugins
if jQuery and jQuery.fn
  jQuery.fn.chocolate = -> new Chocolate @, arguments[0]