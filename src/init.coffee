if not defaultOptions or not templates
  throw new Error "You don't have defaultOptions or templates variables"
  return

choco = 'choco-'

choco_body          = choco + 'body'
choco_error         = choco + 'error'
choco_empty         = choco + 'empty'
choco_hide          = choco + 'hide'
choco_hover         = choco + 'hover'
choco_item          = choco + 'item'
choco_loading       = choco + 'loading'
choco_selected      = choco + 'selected'
choco_show          = choco + 'show'
choco_title         = choco + 'slide-title'
choco_no_thumbnails = choco + 'no-thumbnails'
choco_animated      = choco + 'animated'

existActions = ['next', 'prev', 'close']

env = {}

isOpen = false
isTouch = false
isSupport = not not window.addEventListener

needResize = true

instances = []
opened = null

startTouch = pushState = dummy = ->
session = set: dummy, get: dummy
