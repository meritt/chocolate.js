if not not (window.history and window.history.pushState)
  getImageFromUri = ->
    hash = window.location.hash

    if not hash and isOpen
      opened.close()
      return

    if isOpen
      item = opened.storage.search hash
      if item
        opened.select item, false
        return

    for chocolate in instances
      item = chocolate.storage.search hash
      if item
        opened.close() if isOpen
        chocolate.open item, false
        return

  if 'onhashchange' of window
    addEvent window, 'hashchange', ->
      getImageFromUri()
      return

  addEvent document, 'DOMContentLoaded', ->
    getImageFromUri()
    return

  pushState = (title, hash) ->
    title = title or ''
    hash = hash or ''

    window.history.pushState null, title, "##{hash}"
    return