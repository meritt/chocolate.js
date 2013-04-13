"use strict"

merge = (o1, o2) ->
    return o1 if o1 == null or o2 == null
    for key of o2
        o1[key] = o2[key] if o2.hasOwnProperty key
    o1

_elements = {}
counter = 0

class ChocolateStorage

    add: (options) ->
        _elements[counter] = merge {
                'cid': counter, # ID
                'name': '',    # title
                'thumb': '',   # preview
                'file': '',    # filename
                'orig': '',    # original
                'w': null,     # width
                'h': null      # height
            }, options
        merge {}, _elements[counter++]

    get: (key, fn) ->
        item = _elements[key]
        if item.h isnt null and item.w isnt null or item.origin is ''
            fn merge {},item
        image = new Image()
        image.src = item.orig
        image.addEventListener "error", () ->
            item.orig = ''
            fn merge {},item
        , false
        image.addEventListener "load", () ->
            item.w = image.naturalWidth
            item.h = image.naturalHeight
            fn merge {},item
        , false

    next: (key, fn) ->
        len = @length()
        while not _elements[++key]? and key < len then
        @get key, fn if _elements[key]?

    prev: (key, fn) ->
        while not _elements[--key]? and key > -1 then
        @get key, fn if _elements[key]?

    length: () ->
        return Object.keys(_elements).length if Object.keys?
        i = 0
        for key of _elements
            i++ if _elements.hasOwnProperty key
        i

window.ChocolateStorage = ChocolateStorage
