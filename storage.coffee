
class ChocolateStorage

    merge = (o1, o2) ->
        return o1 if o1 == null or o2 == null
        for key of o2
            o1[key] = o2[key] if o2.hasOwnProperty key
        o1

    constructor: () ->
        @_elements = []
        @length = 0

    add: (options) ->
        @_elements[@length] = merge {
                'i': @length, # ID
                't': '',      # title
                'p': '',      # preview
                'f': '',      # filename
                'o': '',      # original
                'w': null,    # width
                'h': null     # height
            }, options
        merge {}, @_elements[@length++]

    get: (key, fn) ->
        item = @_elements[key]
        if item.h? and item.w? or item.o == ''
            fn item
            return item
        image = new Image
        image.src = item.o
        image.addEventListener "error", () ->
            item.o = ''
            item.w = 0
            item.h = 0
            fn item
            item
        , false
        image.addEventListener "load", () ->
            item.w = image.naturalWidth
            item.h = image.naturalHeight
            fn item
            item
        , false
        item

    next: (key, fn) ->
        if ++key < @length
            console.log 'next '+key
            return @get key, fn
        false

    prev: (key, fn) ->
        if --key > -1
            console.log 'prev '+key
            return @get key, fn
        false


window.ChocolateStorage = ChocolateStorage
