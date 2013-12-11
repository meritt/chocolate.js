isTouch = do ->
  el = document.createElement 'div'
  el.setAttribute 'ongesturestart', 'return;'
  el.setAttribute 'ontouchstart', 'return;'
  return 1 if typeof el.ontouchstart is "function"
  return 2 if typeof el.ongesturestart is "function"
  return 0




getOffset = (element) ->
  style = getStyle element
  reg = /matrix\(([0-9-\.,\s]*)\)/
  tr = style('transform') || style('-webkit-transform') || style('-ms-transform') || ''
  if reg.test tr
    tr = reg.exec(tr)[1].split(',')[4].trim() || 0
  else
    tr = 0
  return toInt tr




round = do ->
  length = window.innerHeight * 0.25
  (t, offset) ->
    offset = Math.abs offset
    if (t.x0 - t.x > length) or (t.x - t.x0 < length)
      return Math.ceil offset
    return Math.floor offset




class Touch

  eventTypes = ["end", "cancel", "leave", "move", "start"]

  constructor: (element, opts) ->
    keys = Object.keys opts
    @finger = {}

    that = @
    keys.forEach (key) ->
      fn = that[key] opts[key], that
      addEvent element, "touch#{key}", fn
      if (key is "end" and not opts.leave)
        addEvent element, "touchleave", fn




  start: (callback) ->
    finger = @finger
    (event) ->
      return unless checkTouch event, 'touchstart'
      return if event.changedTouches.length isnt 1

      t = captureFinger event.changedTouches.item 0
      if t
        finger[key] = value for own key, value of t
        finger.x0 = finger.x
        finger.y0 = finger.y
        event.preventDefault() if callback finger




  move: (callback) ->
    finger = @finger
    (event) ->
      return unless checkTouch event, 'touchmove'

      t = captureFinger getTouch event.changedTouches, finger.id
      if t
        t.dx = (t.x - finger.x) || 0
        t.dy = (t.y - finger.y) || 0
        finger.x = t.x
        finger.y = t.y
        t.x0 = finger.x0
        t.y0 = finger.y0
        event.preventDefault() if callback t




  end: (callback) ->
    finger = @finger
    (event) ->
      if not (checkTouch(event, 'touchend') or checkTouch(event, 'touchleave'))
        return
      t = captureFinger getTouch event.changedTouches, finger.id
      if t
        t.dx = (t.x - finger.x) || 0
        t.dy = (t.y - finger.y) || 0
        t.x0 = finger.x0
        t.y0 = finger.y0
        event.preventDefault() if callback t




  checkTouch = (event, type) -> event.type is type




  getTouch = (touchList, id) ->
    res = false;
    [].forEach.call touchList, (touch) ->
      res = touch if (touch.identifier is id)
    res




  captureFinger = (touch) ->
    id: touch.identifier
    x: touch.pageX
    y: touch.pageY




Chocolate::initTouch = (env) ->
  return false if isTouch is 0

  isThumbing = false
  isClosing = false
  max = -1

  opacity = 1

  overlay = @overlay

  transparent = (n) ->
    opacity = n
    setStyle overlay, opacity: n

  addClass overlay, 'touch'
  addEvent @slider, 'click', (event) ->
    event.preventDefault()
    event.stopPropagation()

  addEvent @slider, 'hover', (event) ->
    event.preventDefault()
    event.stopPropagation()

  addEvent @slider, ['transitionend', 'webkitTransitionEnd'], =>
    removeClass @slider, 'animated'

  addEvent overlay, ['transitionend', 'webkitTransitionEnd'], =>
    removeClass overlay, 'animated'
    return unless isClosing
    @close()
    transparent 1

  t = new Touch overlay,
    start: (t) ->
      false

    move: (t) =>
      s = getOffset @slider
      dx = Math.abs(t.x0 - t.x)
      dy = Math.abs(t.y0 - t.y)
      if dx > dy
        isThumbing = true
        isClosing = false
        transparent 1
        translate @slider, s + t.dx
      else
        isClosing = true
        isThumbing = false
        transparent Math.round((1 - dy / env.h)*100)/100
      true

    end: (t) =>
      if isThumbing
        addClass @slider, 'animated'
        max = @storage.length() - 1 if max is -1
        s = getOffset @slider
        s = round t, (s / env.w)
        @select squeeze s, 0, max
      if isClosing
        addClass overlay, 'animated'
        if opacity < 0.7
          transparent 0
        else
          transparent 1
          isClosing = false
      false

  true
