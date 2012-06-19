fs      = require 'fs'
url     = require 'url'
http    = require 'http'
util    = require 'util'
eco     = require 'eco'
colors  = require 'colors'
mime    = require 'mime'
less    = require 'less'
db      = require 'dirty'

# Log errors without throwing an exception but closing the connection.
log = (error, response) ->
    console.log error.message.red
    response.writeHead 404
    response.end()

# Eco template rendering.
render = (request, response, path, data={}) ->
    console.log "#{request.method} #{request.url}".bold

    fs.readFile "./server/templates/#{path}.eco", "utf8", (err, template) ->
        return log err, response if err

        resource = eco.render template, data
        response.writeHead 200,
            'Content-Type':  'text/html'
            'Content-Length': resource.length
        response.write resource
        response.end()

# LESS CSS rendering.
css = (request, response, path) ->
    fs.readFile path, "utf8", (err, f) ->
        return log err, response if err

        less.render f, (err, resource) ->
            return log err, response if err

            # Info header about the source.
            t = resource.split("\n") ; t.splice(0, 0, "/* #{path} */\n") ; resource = t.join("\n")

            response.writeHead 200,
                'Content-Type':  'text/css'
                'Content-Length': resource.length
            response.write resource
            response.end()

server = http.createServer (request, response) ->

    if request.method is 'GET'
        switch request.url.split('?')[0]
            when '/'
                render request, response, 'dashboard'
            when '/documentation'
                render request, response, 'documentation'
            when '/message'
                # Parse and save message under its timestamp.
                message = url.parse(request.url, true).query ; delete message['callback']
                messages.set message._, url.parse(request.url, true).query, -> response.end()
            else
                # Public resource?
                console.log "#{request.method} #{request.url}".grey

                file = "./server#{request.url}"
                # LESS?
                if file[-9...] is '.less.css'
                    css request, response, file.replace('.less.css', '.less')
                else
                    fs.stat file, (err, stat) ->
                        if err
                            # 404.
                            console.log "#{request.url} not found".red
                            response.writeHead 404
                            response.end()
                        else
                            # Stream file.
                            response.writeHead 200,
                                "Content-Type":   mime.lookup file
                                "Content-Length": stat.size

                            util.pump fs.createReadStream(file), response, (err) ->
                                return log err, response if err
    
    else log { 'message': 'No matching route' }, response

# Connect to DB.
messages = db "#{__dirname}/data/messages.json"
messages.on "load", ->
    # Fire up the server.
    server.listen 1116
    console.log "Listening on port 1116".green.bold