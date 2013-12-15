choco_touch = choco + 'touch'

touchType = do ->
  return 0 unless isSupport

  element = document.createElement 'div'

  element.setAttribute 'ongesturestart', 'return'
  return 2 if typeof element.ongesturestart is 'function'

  element.setAttribute 'ontouchstart', 'return'
  return 1 if typeof element.ontouchstart is 'function'

  return 0

if touchType isnt 0
  isTouch = true

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

    return (touch, offset) ->
      offset = Math.abs offset

      if (touch.x0 - touch.x > length) or (touch.x - touch.x0 < length)
        return Math.ceil offset

      return Math.floor offset

  getTouch = (touches, finger) ->
    for touch in touches when touch.identifier is finger
      return touch

    return false

  capture = (touch) ->
    id: touch.identifier
    x: touch.pageX
    y: touch.pageY

  startTouch = (chocolate) ->
    getEnv()

    isThumbing = false
    isClosing = false

    max = -1
    opacity = 1

    finger = {}

    transparent = (level) ->
      opacity = level
      setStyle chocolate.overlay, opacity: level
      return

    finish = ->
      removeClass chocolate.overlay, choco_animated
      return unless isClosing

      chocolate.close()
      transparent 1

      return

    start = (event) ->
      return if event.changedTouches.length isnt 1

      touch = capture event.changedTouches.item 0
      return unless touch

      for own key, value of touch
        finger[key] = value

      finger.x0 = finger.x
      finger.y0 = finger.y

    move = (event) ->
      touch = capture getTouch event.changedTouches, finger.id
      return unless touch

      dx = (touch.x - finger.x) or 0

      finger.x = touch.x
      finger.y = touch.y

      distanceX = Math.abs(finger.x0 - touch.x)
      distanceY = Math.abs(finger.y0 - touch.y)

      isThumbing = distanceX > distanceY
      isClosing = not isThumbing

      sliderOffset = getOffset chocolate.slider

      if isThumbing
        transparent 1
        translate chocolate.slider, sliderOffset + dx
      else
        transparent Math.round((1 - distanceY / env.h) * 100) / 100

      stop event
      return

    end = (event) ->
      touch = capture getTouch event.changedTouches, finger.id
      return unless touch

      touch.x0 = finger.x0
      touch.y0 = finger.y0

      if isThumbing
        addClass chocolate.slider, choco_animated

        if max is -1
          max = chocolate.storage.length() - 1

        sliderOffset = getOffset chocolate.slider
        sliderOffset = touchShift touch, (sliderOffset / env.w)

        chocolate.select squeeze sliderOffset, 0, max

      if isClosing
        addClass chocolate.overlay, choco_animated

        if opacity < 0.7
          transparent 0
        else
          transparent 1
          isClosing = false

      finger = {}
      return

    addClass chocolate.overlay, choco_touch

    addEvent chocolate.slider, 'click', (event) ->
      stop event
      return

    addEvent chocolate.slider, 'hover', (event) ->
      stop event
      return

    addEvent chocolate.slider, 'transitionend', ->
      removeClass chocolate.slider, choco_animated
      return

    addEvent chocolate.slider, 'webkitTransitionEnd', ->
      removeClass chocolate.slider, choco_animated
      return

    addEvent chocolate.overlay, 'transitionend', ->
      finish()
      return

    addEvent chocolate.overlay, 'webkitTransitionEnd', ->
      finish()
      return

    addEvent chocolate.overlay, 'touchstart', start
    addEvent chocolate.overlay, 'touchmove', move
    addEvent chocolate.overlay, 'touchend', end
    addEvent chocolate.overlay, 'touchcancel', end
    addEvent chocolate.overlay, 'touchleave', end
