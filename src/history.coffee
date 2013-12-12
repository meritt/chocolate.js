isHistory = not not (window.history and history.pushState)

if isHistory
  getImageFromUri = ->
    hash = window.location.hash
    return unless hash

    if isOpen
      item = opened.storage.search hash
      return opened.select item if item

    for chocolate in instances
      item = chocolate.storage.search hash
      if item
        opened.close() if isOpen
        chocolate.open item
        return

  if 'onhashchange' of window
    addEvent window, 'hashchange', ->
      getImageFromUri()
      return

  addEvent window, 'load', ->
    getImageFromUri()
    return

  pushState = (title, hash) ->
    title = title or ''
    hash = hash or ''

    window.history.pushState null, title, "##{hash}"
    return