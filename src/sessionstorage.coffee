if not not window.sessionStorage
  session = do ->
    key = choco + 'thumbnails'

    set: (value) ->
      window.sessionStorage.setItem key, +value
      return

    get: ->
      option = window.sessionStorage.getItem key
      return option and option is '0'
