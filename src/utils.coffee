isHistory = not not (window.history and history.pushState)

getTarget = (element, selector) ->
  if selector?
    target = element.querySelector selector
  else
    target = element
  target




changeHandler = (element, event, listener, selector, method) ->
  target = getTarget element, selector
  if target?
    unless event instanceof Array
      event = [event]
    for ev in event
      target["#{method}EventListener"] ev, listener, false

addHandler = (element, event, listener, selector) ->
  changeHandler element, event, listener, selector, 'add'

removeHandler = (element, event, listener, selector) ->
  changeHandler element, event, listener, selector, 'remove'




changeClass = (element, className, selector, method) ->
  target = getTarget element, selector
  if target? and target.classList?
    return target.classList[method] className
  else
    return false

addClass = (element, className, selector) ->
  changeClass element, className, selector, 'add'

removeClass = (element, className, selector) ->
  changeClass element, className, selector, 'remove'

toggleClass = (element, className, selector) ->
  changeClass element, className, selector, 'toggle'

hasClass = (element, className, selector) ->
  changeClass element, className, selector, 'contains'



getAttribute = (element, attribute) ->
  element.getAttribute attribute




merge = (o1, o2) ->
  for own key, value of o2
    if value instanceof Object
      o1[key] = merge o1[key], value
    else
      o1[key] = value
  o1




mustache = (a, b) ->
  a.replace /\{\{([^{}]+)\}\}/g, (c, d) ->
    if b.hasOwnProperty(d) && b[d]?
      return "#{b[d]}"
    else
      return ""




beforeend = (element, string) ->
  children = element.children
  len = children.length
  element.insertAdjacentHTML 'beforeend', string
  [].slice.call children, len, children.length




toInt = (string) -> parseInt(string, 10) || 0




squeeze = (n, min, max) ->
  if min > max
    t = min
    min = max
    max = t
  if n < min
    n = min
  if n > max
    n = max
  n




translate = do ->
  property = false
  has3d = false

  element = document.createElement 'div'
  property = 'transform' if element.style.transform

  prefixes = ['Webkit', 'Moz', 'O', 'ms']

  if property is false
    for prefix in prefixes when element.style["#{prefix}Transform"] isnt undefined
      property = "#{prefix}Transform"

  has3d = true if property is 'WebkitTransform'
  if property isnt false
    (element, s) ->
      if has3d
        s = "translate3d(#{s}px, 0, 0)"
      else
        s = "translateX(#{s}px)"
      element.style[property] = s




getStyle = (element) ->
  style = getComputedStyle element
  return (property) ->
    style.getPropertyValue.call style, property




setStyle = (element, styles) ->
  properties = Object.keys styles
  properties.forEach (property) ->
    prop = property.replace /-([a-z])/g, (g) -> g[1].toUpperCase()
    element.style[prop] = styles[property]




scale = (w1, h1, w2, h2) ->

  ratio = w1 / h1

  if w1 > w2
    w1 = w2
    h1 = w2 / ratio

  if h1 > h2
    w1 = h2 * ratio
    h1 = h2


  return [toInt(w1), toInt(h1)]




offsetWidth = (element) -> element.offsetWidth
offsetHeight = (element) -> element.offsetHeight




pushState = do ->
  if isHistory
    return (title, hash) ->
      title = title or ''
      hash = hash or ''
      history.pushState null, title, "##{hash}"
  else
    return () ->
