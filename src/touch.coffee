if isTouch

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
