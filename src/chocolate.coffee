counter = 0

existActions = ['next', 'prev', 'close']

isHistory = not not (window.history and history.pushState)

updateBasedir = (template, basedir) ->
  template.replace /\{\{basedir\}\}/g, basedir

class Chocolate
  images: {}
  current: null

  ###
   Конструктор
  ###
  constructor: (images, options = {}) ->
    throw "You don't have defaultOptions or templates variables" if not defaultOptions or not templates

    @options  = $.extend defaultOptions, options
    isHistory = false if not @options.history

    template = templates['overlay']
    template = template.replace '{{spinner}}', templates['spinner']
    template = template.replace '{{thumbnails}}', if @options.thumbnails then templates['thumbnails'] else ''
    template = updateBasedir template, @options.basedir

    @overlay = $(template).appendTo 'body'

    elements = ['container', 'spinner', 'leftside', 'rightside']
    elements.push 'thumbnails' if @options.thumbnails

    @[element] = @overlay.find '.choco-' + element for element in elements

    @overlay.find('.choco-close').click (event) => @close()

    @_prepareActionFor element for element in ['overlay', 'container', 'leftside', 'rightside']

    if isHistory
      $(window).bind 'popstate', (event) =>
        cid = @getImageFromUri()
        if cid > 0 and cid isnt @current
          if @current is null then @show cid else @updateImage cid, false

    $(window).bind 'keyup', (event) =>
      if @overlay.hasClass 'show'
        switch event.keyCode
          when 27    # ESC
            @close()
          when 37    # Left arrow
            @prev()
          when 39    # Right arrow
            @next()

    @add images if images

  _prepareActionFor: (element) ->
    method = if @options.actions[element] in existActions then @options.actions[element] else false
    if method
      verify = @[element].attr 'class'
      @[element].click (event) => @[method]() if $(event.target).hasClass verify
    @

  getImageFromUri: ->
    hash = window.location.hash
    if hash then parseInt hash.replace('#image', ''), 10 else 0

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

  _addToGallery: (data, image) ->
    return unless data.source

    cid = ++counter

    data.thumbnail = data.source unless data.thumbnail
    @images[cid] = data

    if image
      showFirstImage = (event, cid) =>
        event.stopPropagation()
        event.preventDefault()
        @show cid

      image.addClass('choco-item').click (event) -> showFirstImage event, cid

      preload = new Image()
      preload.src = data.thumbnail
      preload.onload = (event) =>
        image.before templates['image-hover'].replace '{{cid}}', cid
        $('[data-sglid=' + cid + ']').css(width: image.width(), height: image.height()).click (event) ->
          showFirstImage event, cid

  ###
   Показать изображение на большом экране
  ###
  show: (cid) ->
    cid = @getImageFromUri() unless cid?
    cid = 1 if cid <= 0
    throw 'Image not found' unless @images[cid]?

    @current = cid if @current is null

    @createThumbnails() if @options.thumbnails
    @updateImage cid
    @overlay.addClass 'show'
    @

  close: ->
    @overlay.removeClass 'show'
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

    if @options.thumbnails
      @thumbnails.find('.selected').removeClass 'selected'
      @thumbnails.find('[data-cid=' + cid + ']').addClass 'selected'

    if isHistory and updateHistory
      title = if @images[cid].title then 'Image: ' + @images[cid].title else null
      history.pushState null, title, '#image' + cid

    @getImageSize cid, (cid) ->
      @container.addClass 'show'

      image = @images[cid]

      @updateDimensions image.width, image.height

      @container.css 'background-image', 'url(' + image.source + ')'
      @container.html if image.title then templates['image-title'].replace '{{title}}', image.title else ''
    @

  ###
   Обновление размеров блока с главным изображением
  ###
  getImageSize: (cid, after = ->) ->
    image = @images[cid]

    if not image.width or not image.height
      @spinner.removeClass 'hide'

      element     = new Image()
      element.src = image.source

      element.onload = (event) =>
        @spinner.addClass 'hide'

        @images[cid].width  = element.width
        @images[cid].height = element.height

        delete element

        after.call @, cid
    else
      after.call @, cid

  ###
   Обновление размеров блока с главным изображением
  ###
  updateDimensions: (width, height) ->
    thumbnails = if not @options.thumbnails or @thumbnails.css('display') is 'none' then 0 else @thumbnails.height()

    innerWidth   = window.innerWidth
    windowWidth  = innerWidth - 50
    innerHeight  = window.innerHeight
    windowHeight = innerHeight - 50 - thumbnails

    if width > windowWidth
      height = windowWidth * height / width
      width  = windowWidth

    if height > windowHeight
      width  = windowHeight * width / height
      height = windowHeight

    left = parseInt width / 2, 10
    top  = parseInt height / 2, 10
    top += parseInt thumbnails / 2, 10 if thumbnails > 0

    style = 'width': (innerWidth / 2 - left) + 'px', 'height': innerHeight + 'px'

    @leftside.css  style
    @rightside.css style

    style = 'width': width, 'height': height, 'margin-left': '-' + left + 'px', 'margin-top': '-' + top + 'px'

    @container.css style
    @spinner.css   style
    @

  ###
   Создание панели для тумбнейлов
  ###
  createThumbnails: ->
    return @ if not @options.thumbnails or not @current or @images.length <= 1

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

    @thumbnails.html(content).find('.choco-thumbnail').click (event) ->
      _this.updateImage parseInt $(@).attr('data-cid'), 10

    @overlay.find('.choco-thumbnails-toggle').click (event) ->
      method = if _this.thumbnails.hasClass 'hide' then 'removeClass' else 'addClass'

      _this.thumbnails[method] 'hide'
      $(@)[method] 'hide'

      _this.updateDimensions current.width, current.height

    @

# Экспорт в глобальное пространство
window.chocolate = Chocolate

# Подключение к jQuery Plugins
if jQuery and jQuery.fn
  jQuery.fn.chocolate = -> new Chocolate @, arguments[0]