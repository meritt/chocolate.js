isStorage = 'localStorage' of window and window['localStorage']?
isHistory = not not (window.history and history.pushState)

addHandler = (element, event, listener, selector) ->
  target = getTarget element, selector
  if target?
    unless event instanceof Array
      event = [event]
    for ev in event
      target.addEventListener ev, listener, false




removeHandler = (element, event, listener, selector) ->
  target = getTarget element, selector
  if target?
    unless event instanceof Array
      event = [event]
    for ev in event
      target.removeEventListener ev, listener, false




hasClassList = (element, selector) ->
  target = getTarget element, selector
  if target? and target.classList?
    return target.classList
  else
    return false




addClass = (element, className, selector) ->
  list = hasClassList element, selector
  list.add className if list




removeClass = (element, className, selector) ->
  list = hasClassList element, selector
  list.remove className if list




toggleClass = (element, className, selector) ->
  list = hasClassList element, selector
  list.toggle className if list




hasClass = (element, className, selector) ->
  list = hasClassList element, selector
  list.contains className if list




getTarget = (element, selector) ->
  if selector?
    target = element.querySelector selector
  else
    target = element
  target




merge = (o1, o2) ->
  for own key, value of o2
    if value instanceof Object
      o1[key] = merge o1[key], value
    else
      o1[key] = value
  o1




mustache = (a, b) ->
  a.replace /\{\{([^{}]+)\}\}/g, (c, d) ->
    if b.hasOwnProperty d
      return "#{b[d]}"
    else
      return ""




beforeend = (element, string) ->
  children = element.children
  len = children.length
  element.insertAdjacentHTML 'beforeend', string
  [].slice.call children, len, children.length




toInt = (string) -> parseInt string, 10




translate = do ->
  property = false
  has3d = false

  element = document.createElement 'div'
  property = 'transform' if element.style.transform

  prefixes = ['Webkit', 'Moz', 'O', 'ms']

  if property is false
    for prefix in prefixes when element.style["#{prefix}Transform"] isnt undefined
      property = "#{prefix}Transform"

  has3d = true if prefix is 'Webkit'
  if property isnt false
    (element, s) ->
      if has3d
        s = "translate3d(#{s}px, 0, 0)"
      else
        s = "translateX(#{s}px)"
      element.style[property] = s




getStyle = (element) ->
  style = getComputedStyle element
  return (property) -> style.getPropertyValue.call style, property




setStyle = (element, styles) ->
  properties = Object.keys styles
  properties.forEach (property) ->
    prop = property.replace /-([a-z])/g, (g) -> g[1].toUpperCase()
    element.style[prop] = styles[property]




pushState = do ->
  if isHistory
    return (title, hash) ->
      title = title or ''
      hash = hash or ''
      history.pushState null, title, "##{hash}"
  else
    return () ->

