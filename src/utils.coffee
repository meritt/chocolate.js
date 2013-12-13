startTouch = pushState = dummy = ->
session = set: dummy, get: -> true

merge = (o1, o2) ->
  for own key, value of o2
    if value instanceof Object
      o1[key] = merge o1[key], value
    else
      o1[key] = value

  return o1

mustache = (a, b) ->
  a.replace /\{\{([^{}]+)\}\}/g, (c, d) ->
    if b.hasOwnProperty(d) && b[d]?
      return "#{b[d]}"
    else
      return ''

getTarget = (element, selector) ->
  return element.querySelector selector if selector
  return element

addEvent = (element, event, listener, selector) ->
  target = getTarget element, selector
  return unless target

  target.addEventListener event, listener, false
  return

classList = (element, className, selector, method) ->
  target = getTarget element, selector
  return false if not target or not target.classList
  return target.classList[method] className

addClass = (element, className, selector) ->
  classList element, className, selector, 'add'

removeClass = (element, className, selector) ->
  classList element, className, selector, 'remove'

toggleClass = (element, className, selector) ->
  classList element, className, selector, 'toggle'

hasClass = (element, className, selector) ->
  classList element, className, selector, 'contains'

getAttribute = (element, attribute) ->
  element.getAttribute attribute

getStyle = (element) ->
  style = window.getComputedStyle element
  return (property) ->
    style.getPropertyValue property

setStyle = (element, params) ->
  element.style[toCamelCase property] = value for own property, value of params

toCamelCase = (str) ->
  str.replace /-([a-z])/g, (str) -> str[1].toUpperCase()

offsetWidth = (element) ->
  element.offsetWidth

offsetHeight = (element) ->
  element.offsetHeight

beforeEnd = (element, template) ->
  element.insertAdjacentHTML 'beforeend', template
  element.lastElementChild

stop = (event) ->
  event.stopPropagation()
  event.preventDefault()
  return

toInt = (string) ->
  parseInt(string, 10) or 0

squeeze = (n, min, max) ->
  [min, max] = [max, min] if min > max

  n = min if n < min
  n = max if n > max

  return n

scale = (w1, h1, w2, h2) ->
  ratio = w1 / h1

  if w1 > w2
    w1 = w2
    h1 = w2 / ratio

  if h1 > h2
    w1 = h2 * ratio
    h1 = h2

  return [toInt(w1), toInt(h1)]

translate = do ->
  property = false
  accelerate = false

  element = document.createElement 'div'
  property = 'transform' if element.style.transform

  unless property
    for prefix in ['Webkit', 'Moz', 'O', 'ms']
      prop = "#{prefix}Transform"
      if element.style[prop] isnt undefined
        property = prop
        break

  unless property
    dummy
  else
    element.style[property] = 'translate3d(1px,0,0)'
    accelerate = getStyle(element)(property)

    (element, shift) ->
      if accelerate isnt undefined
        shift = "translate3d(#{shift}px,0,0)"
      else
        shift = "translateX(#{shift}px)"

      element.style[property] = shift
