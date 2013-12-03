
class ChocolateStorage

  constructor: (repeat) ->
    @repeat = not not repeat
    @images = {}
    @counter = 0




  add: (options) ->
    return false unless options.orig
    cid = @counter++
    fragments    = options.orig.split '/'
    options.hashbang = fragments[fragments.length-1]
    options.thumb = options.orig unless options.thumb
    options = merge {
        cid: cid, # ID
        name: '',    # title
        thumb: '',   # preview
        hashbang: '',    # filename
        orig: '',    # original
        w: null,     # width
        h: null      # height
      }, options
    @images[cid] = options
    @images[cid]




  get: (key) -> @images[key]




  next: (key) ->
    key = key.cid
    len = @length()
    while not @images[++key]? and key < len then
    if key >= len
      key = if @repeat then 0 else len - 1
    @get key




  prev: (key) ->
    key = key.cid
    len = @length()
    while not @images[--key]? and key > -1 then
    if key < 0
      key = if @repeat then len - 1 else 0
    @get key




  search: (hash) ->
    cid = false
    for own key, image of @images
      if "##{image.hashbang}" is hash
        cid = key
        break
    @images[cid] if cid




  length: () ->
    return Object.keys(@images).length if Object.keys?
    i = 0
    for key of @images
        i++ if @images.hasOwnProperty key
    i
