if not not window.sessionStorage
  session = do ->
    key = choco + 'thumbnails'

    set: (show = true) ->
      window.sessionStorage.setItem key, +show
      return

    get: ->
      option = window.sessionStorage.getItem key
      return option and option is '0'
