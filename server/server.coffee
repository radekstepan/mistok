fs      = require 'fs'
url     = require 'url'
http    = require 'http'
util    = require 'util'
eco     = require 'eco'
colors  = require 'colors'
mime    = require 'mime'
less    = require 'less'
tiny    = require 'tiny'

# -------------------------------------------------------------------
# Routes
router = routes: {}
router.get = (route, callback) -> router.routes[route] = callback

# Dashboard.
router.get '/', (request, response) ->
    now = new Date()

    # Get exceptions over past 14 days.
    fourteen = now.getTime() - 1.2096e9
    db.messages.fetch
        desc: 'timestamp'
    , ((doc, key) ->
        doc.type is 'exception'
    ), (error, exceptions) ->
        return log error, response if error and error.message isnt 'No records.'

        # Get the full log.
        db.messages.fetch desc: 'timestamp', ( -> true), (error, log) ->
            return log error, response if error and error.message isnt 'No records.'

            # Calculate the stats.
            today = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 9).getTime() # today at 9AM

            stats =
                today:      [ 0, 0 ]
                lastToday:  [ 0, 0 ]
                week:       [ 0, 0 ]
                lastWeek:   [ 0, 0 ]
                month:      [ 0, 0 ]
                lastMonth:  [ 0, 0 ]
            for message in log
                type = (message.type is 'exception') + 0
                if message.timestamp > today # today
                    stats.today[type] += message.count
                    stats.week[type] += message.count
                    stats.month[type] += message.count
                else if message.timestamp > today - 8.64e7 # yesterday
                    stats.lastToday[type] += message.count
                    stats.week[type] += message.count
                    stats.month[type] += message.count
                else if message.timestamp > today - 6.048e8 # this week
                    stats.week[type] += message.count
                    stats.month[type] += message.count
                else if message.timestamp > today - 1.2096e9 # last week
                    stats.lastWeek[type] += message.count
                    stats.month[type] += message.count
                else if message.timestamp > today - 2.592e9 # this month (assume 30)
                    stats.month[type] += message.count
                else if message.timestamp > today - 5.184e9 # last month (assume 30)
                    stats.lastMonth[type] += message.count

            render request, response, 'dashboard',
                'log':        log
                'stats':      stats
                'exceptions': exceptions

# Documentation.
router.get '/documentation', (request, response) ->
    render request, response, 'documentation'

# Receive message.
router.get '/message', (request, response) ->
    message = url.parse(request.url, true).query
    message.timestamp = new Date().getTime()
    message.count = 1

    # Do we have the same message from upto an hour ago?
    hour = message.timestamp - 3.6e6
    db.messages.fetch
        desc: 'timestamp'
        limit: 1
    , ((doc, key) ->
        (doc.timestamp >= hour and doc.type is message.type and doc.body is message.body and doc.url is message.url and doc.line is message.line)
    ), (error, results) ->
        return log error, response if error and error.message isnt 'No records.'

        for result in results
            return db.messages.update(result._key,
                count: result.count + 1
            , (error) ->
                return log error, response if error
                db.messages.dump true, ->
                    console.log 'Database dumped'.blue
                    response.end()
            )

        db.messages.guid (key) ->
            db.messages.set key, message, (error) ->
                return log error, response if error
                db.messages.dump true, ->
                    console.log 'Database dumped'.blue
                    response.end()

# -------------------------------------------------------------------
# Database helper.
db = {}
tiny::guid = (callback) ->
    self = @
    hex = -> (((1 + Math.random()) * 0x10000) | 0).toString(16).substring 1
    
    (unique = ->
        key = "#{hex()}-#{hex()}-#{hex()}"
        self.get key, (error, data) ->
            if error
                if error.message is 'Not found.' then callback key else throw new String(error).red
            else
                console.log "Key #{key} already used".blue
                unique()
    )()

# -------------------------------------------------------------------
# Error 404 logging.
log = (error, response) ->
    console.log new String(error.message).red
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
# Load the database.
tiny "#{__dirname}/data/messages.json", (error, database) ->
    throw new String(error).red if error
    
    db.messages = database

    # Fire up the server.
    server.listen 1116
    console.log "Listening on port 1116".green.bold