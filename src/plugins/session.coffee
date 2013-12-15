if not not window.sessionStorage
  session = do ->
    key = choco + 'thumbnails'

    set: (value) ->
      window.sessionStorage.setItem key, +value
      return

    get: ->
      window.sessionStorage.getItem key
