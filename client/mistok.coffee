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

        params = []
        for key, value of obj
            params.push "#{key}=#{encodeURIComponent(value)}"
        (new Image).src = "#{@server}/message?" + params.join('&')

    constructor: ->

        window.onerror = (msg, url, line) =>
            data =
                type: 'exception'
                body: msg ? 'No message'

            data.url = url ? ''
            data.line = line ? ''
          
            @log data

window.Mistok = new Mistok()