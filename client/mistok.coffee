# For our purposes, `$` means jQuery or Zepto.
$ = window.jQuery or window.Zepto

class Mistok

    log: (obj, callback) ->
        throw 'Please set the location of the server.' unless @server?

        if typeof (obj) is "string"
            obj =
                type: 'message'
                body: obj
    
        throw "Make sure the object meets the form: { type:'', body:'' }" unless obj.type? or obj.body?
        throw 'Please set your client key.' unless @key?
        
        obj.key = @key
        obj.url = obj.url ? document.URL

        $.ajax
            url:      "#{@server}/message"
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