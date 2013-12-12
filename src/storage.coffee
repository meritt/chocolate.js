class Storage
  images: {}
  counter: 0

  constructor: (repeat) ->
    @repeat = not not repeat

  add: (image) ->
    return false unless image.orig

    cid = @counter++

    fragments = image.orig.split '/'

    image.hashbang = fragments[fragments.length-1]
    image.thumb = image.orig unless image.thumb

    @images[cid] = merge {
      cid: cid,     # id
      name: '',     # title
      thumb: '',    # preview
      hashbang: '', # filename
      orig: '',     # original
      w: null,      # width
      h: null       # height
    }, image

    return @images[cid]

  get: (cid) ->
    return @images[cid]

  next: (current) ->
    cid = current.cid + 1
    cid = 0 if @repeat and not @images[cid]
    return @images[cid]

  prev: (current) ->
    cid = current.cid - 1
    cid = @length() - 1 if @repeat and cid < 0
    return @images[cid]

  length: ->
    return Object.keys(@images).length

  search: (hash) ->
    for own key, image of @images
      return image if "##{image.hashbang}" is hash

    return false
