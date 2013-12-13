getOffset = (element) ->
  style = getStyle element
  regex = /matrix\(([0-9-\.,\s]*)\)/

  transform = style('transform') or style('-webkit-transform') or style('-ms-transform') or ''

  if regex.test transform
    transform = regex.exec(transform)[1].split(',')[4].trim() or 0
  else
    transform = 0

  return toInt transform




touchShift = do ->
  length = window.innerHeight * 0.25

  return (t, offset) ->
    offset = Math.abs offset

    if (t.x0 - t.x > length) or (t.x - t.x0 < length)
      return Math.ceil offset

    return Math.floor offset




getTouch = (touchList, id) ->
  res = false
  [].forEach.call touchList, (touch) ->
    res = touch if (touch.identifier is id)
  res




captureFinger = (touch) ->
  id: touch.identifier
  x: touch.pageX
  y: touch.pageY




Chocolate::initTouch = (env) ->
  return false if touchType is 0

  isThumbing = false
  isClosing = false

  max = -1
  opacity = 1

  overlay = @overlay
  slider = @slider

  transparent = (level) ->
    opacity = level
    setStyle overlay, opacity: level
    return

  addClass overlay, 'touch'

  finish = =>
    console.log @
    removeClass overlay, choco_animated
    return unless isClosing

    @close()
    transparent 1

    return


  finger = {}

  start = (event) ->
    return if event.changedTouches.length isnt 1

    t = captureFinger event.changedTouches.item 0
    return unless t
    finger[key] = value for own key, value of t
    finger.x0 = finger.x
    finger.y0 = finger.y

  move = (event) ->
    t = captureFinger getTouch event.changedTouches, finger.id
    return unless t

    t.dx = (t.x - finger.x) || 0
    t.dy = (t.y - finger.y) || 0
    finger.x = t.x
    finger.y = t.y
    t.x0 = finger.x0
    t.y0 = finger.y0

    s = getOffset slider

    dx = Math.abs(t.x0 - t.x)
    dy = Math.abs(t.y0 - t.y)

    if dx > dy
      isThumbing = true
      isClosing = false
      transparent 1
      translate slider, s + t.dx
    else
      isClosing = true
      isThumbing = false
      transparent Math.round((1 - dy / env.h) * 100) / 100
    stop event

  end = (event) =>
    t = captureFinger getTouch event.changedTouches, finger.id
    return unless t
    t.dx = (t.x - finger.x) || 0
    t.dy = (t.y - finger.y) || 0
    t.x0 = finger.x0
    t.y0 = finger.y0
    if isThumbing
      addClass slider, choco_animated
      max = @storage.length() - 1 if max is -1
      s = getOffset slider
      s = touchShift t, (s / env.w)
      @select squeeze s, 0, max
    if isClosing
      addClass overlay, choco_animated
      if opacity < 0.7
        transparent 0
      else
        transparent 1
        isClosing = false

  addEvent slider, 'click', (event) ->
    stop event
    return

  addEvent slider, 'hover', (event) ->
    stop event
    return

  addEvent slider, 'transitionend', ->
    removeClass slider, choco_animated
    return

  addEvent slider, 'webkitTransitionEnd', ->
    removeClass slider, choco_animated
    return


  addEvent overlay, 'transitionend', ->
    finish()
    return

  addEvent overlay, 'webkitTransitionEnd', ->
    finish()
    return

  addEvent overlay, 'touchstart', start
  addEvent overlay, 'touchmove', move
  addEvent overlay, 'touchend', end
  addEvent overlay, 'touchcancel', end
  addEvent overlay, 'touchleave', end

  return true

touchType = do ->
  element = document.createElement 'div'

  element.setAttribute 'ongesturestart', 'return'
  return 2 if typeof element.ongesturestart is 'function'

  element.setAttribute 'ontouchstart', 'return'
  return 1 if typeof element.ontouchstart is 'function'

  return 0
