isSessionStorage = not not window.sessionStorage

if isSessionStorage
  storageKey = "#{choco}thumbnails"

  setThumbnailsSettings = (show = true) ->
    window.sessionStorage.setItem storageKey, +show

  getThumbnailsSettings = ->
    res = window.sessionStorage.getItem(storageKey)
    if res?
      return not not +res
    else
      return true
