# For our purposes, `$` means jQuery or Zepto.
$ = window.jQuery or window.Zepto

class Mistok
    
    log: (obj, callback) ->
        if typeof (obj) is "string"
            obj =
                type: 'message'
                body: obj
    
        throw "Make sure the object meets the form: { type:'', body:'' }" if obj.type is 'undefined' or obj.body is 'undefined'
        throw 'Please set your API key.' if @key is undefined
        
        obj.key = @key
        obj.url = obj.url ? document.URL

        $.ajax
            url:      'http://0.0.0.0:1116/message'
            data:     obj
            dataType: 'jsonp'
            statusCode:
                404: -> callback 404 if callback
                200: -> callback 200 if callback

    constructor: ->

        window.onerror = (msg, url, line) =>
            data =
                type: 'exception'
                body: msg ? 'No message'

            data.url = url ? ''
            data.line = line ? ''
          
            @log data

window.Mistok = new Mistok()