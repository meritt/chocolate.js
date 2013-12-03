isTouch = do ->
  el = document.createElement 'div'
  el.setAttribute 'ongesturestart', 'return;'
  el.setAttribute 'ontouchstart', 'return;'
  return 1 if typeof el.ontouchstart is "function"
  return 2 if typeof el.ongesturestart is "function"
  return 0




getOffset = (element) ->
  style = getComputedStyle element
  reg = /matrix\(([0-9-\.,\s]*)\)/
  tr = style.getPropertyValue('transform') || style.getPropertyValue('-webkit-transform') || style.getPropertyValue('-ms-transform') || ''
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
      addHandler element, "touch#{key}", fn
      if (key is "end" and not opts.leave)
        addHandler element, "touchleave", fn




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
  return if isTouch is 0
  @overlay.classList.add 'touch'
  addHandler @slider, 'click', (event) ->
    event.preventDefault()
    event.stopPropagation()

  addHandler @slider, 'hover', (event) ->
    event.preventDefault()
    event.stopPropagation()

  addHandler @slider, 'transitionend', =>
    @slider.classList.remove 'animated'

  t = new Touch @overlay,
    start: (t) ->
      false

    move: (t) =>
      s = getOffset @slider
      translate @slider, s + t.dx
      true

    end: (t) =>
      max = @slider.children.length - 1
      @slider.classList.add 'animated'
      s = getOffset @slider
      s = round t, (s / env.w)
      s = 0 if s < 0
      s = max if s > max
      @select Math.abs s
      false
