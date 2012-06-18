# For our purposes, `$` means jQuery or Zepto.
$ = window.jQuery or window.Zepto

class Mistok
    
    log: (obj) ->
        if typeof (obj) is "string"
            obj =
                type: "Message"
                body: obj
    
        throw "Make sure the object meets the form: { type:'', body:'' }" if obj.type is 'undefined' or obj.body is 'undefined'
        throw 'Please set your API key.' if @key is undefined
        
        obj.key = @key
        obj.url = obj.url ? document.URL

        $.ajax
            url:      'http://0.0.0.0:1116/message'
            data:     obj
            dataType: 'jsonp'
            success: (data) -> console.log "success"
            error:   (request, status, error) ->

    constructor: ->

        window.onerror = (msg, url, lineno) =>
            data =
                type: 'Exception'
                body: msg ? 'No message'

            data.url = url ? ''
            data.lineno = lineno ? ''
          
            Mistok.log data

window.Mistok = new Mistok()