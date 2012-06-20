fs      = require 'fs'
url     = require 'url'
http    = require 'http'
util    = require 'util'
eco     = require 'eco'
colors  = require 'colors'
mime    = require 'mime'
less    = require 'less'
dirty   = require 'dirty'

# -------------------------------------------------------------------
# Routes
router = routes: {}
router.get = (route, callback) -> router.routes[route] = callback
router.get '/', (request, response) ->
    db.all 'messages', (messages) ->
        render request, response, 'dashboard', 'log': messages

router.get '/documentation', (request, response) ->
    render request, response, 'documentation'

router.get '/message', (request, response) ->
    message = url.parse(request.url, true).query
    db.save 'messages', url.parse(request.url, true).query, -> response.end()

# -------------------------------------------------------------------
# Database
db =
    databases = {}
db.init = (database, callback) ->
    if databases[database] then callback databases[database]
    else
        databases[database] = dirty "#{__dirname}/data/#{database}.json"
        databases[database].on "load", -> callback databases[database]
db.guid = ->
    hex = -> (((1 + Math.random()) * 0x10000) | 0).toString(16).substring 1
    hex() + hex() + "-" + hex() + "-" + hex() + "-" + hex() + "-" + hex() + hex() + hex()
db.save = (database, value, callback) ->
    db.init database, (database) ->
        unique = false
        while not unique
            if database.get(key = db.guid()) is undefined then unique = true
        database.set key, value, -> callback()
db.get = (database, key, callback) ->
    db.init database, (database) ->
        callback database.get(key)
db.all = (database, callback) ->
    db.init database, (database) ->
        callback database._docs

# -------------------------------------------------------------------
# Error 404 logging
log = (error, response) ->
    console.log error.message.red
    response.writeHead 404
    response.end()

# -------------------------------------------------------------------
# Eco template rendering.
render = (request, response, filename, data={}) ->
    console.log "#{request.method} #{request.url}".bold

    fs.readFile "./server/templates/#{filename}.eco", "utf8", (err, template) ->
        return log err, response if err

        resource = eco.render template, data
        response.writeHead 200,
            'Content-Type':  'text/html'
            'Content-Length': resource.length
        response.write resource
        response.end()

# -------------------------------------------------------------------
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

# -------------------------------------------------------------------
# Main rooting.
server = http.createServer (request, response) ->

    if request.method is 'GET'
        route = router.routes[request.url.split('?')[0]]
        if route then route request, response
        else
            # Public resource?
            console.log "#{request.method} #{request.url}".grey

            file = "./server#{request.url}"
            # LESS?
            if file[-9...] is '.less.css'
                css request, response, file.replace('.less.css', '.less')
            else
                # Data folder?
                if request.url[0...5] is '/data'
                    log { 'message': 'Access forbidden' }, response
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

# -------------------------------------------------------------------
# Fire up the server.
server.listen 1116
console.log "Listening on port 1116".green.bold