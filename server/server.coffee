fs      = require 'fs'
urlib   = require 'url'
http    = require 'http'
util    = require 'util'
eco     = require 'eco'
colors  = require 'colors'
mime    = require 'mime'
less    = require 'less'
tiny    = require 'tiny'
openid  = require 'openid'
ua      = require 'ua-parser'
mongodb = require 'mongodb'

# -------------------------------------------------------------------
# Config.
json = fs.readFileSync './config.json'
try
    CONFIG = JSON.parse json
catch err
    throw err.message.red

if process.env.PORT? # Heroku
    port = process.env.PORT
    host = CONFIG.production.host
    db = new mongodb.Db(CONFIG.production.mongodb.db,
        new mongodb.Server(CONFIG.production.mongodb.host, CONFIG.production.mongodb.port,
            'auto_reconnect': true
        )
    )
    db.open (err) ->
        throw err.message.red if err
        db.authenticate process.env.MONGOHQ_USER, process.env.MONGOHQ_PASSWORD, (err) ->
            throw err.message.red if err

            startup()

else # Local development.
    port = CONFIG.development.port
    host = CONFIG.development.host
    db = new mongodb.Db(CONFIG.development.mongodb.db,
        new mongodb.Server(CONFIG.development.mongodb.host, CONFIG.development.mongodb.port,
            'auto_reconnect': true
        )
    )
    db.open (err, db) ->
        throw err.message.red if err

        startup()

# -------------------------------------------------------------------
# Routes.
router = routes: {}
router.get = (route, callback) -> router.routes[route] = callback

# Dashboard.
router.get '/', (request, response) ->
    authorize request, response, (user) ->

        # Calculate the stats.
        now = new Date()
        today = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0).getTime()

        # Full log.
        log = []
        # Will hold exceptions of past 14 days.
        exceptions = []
        # Last 30 days in the chart.
        chart = [0...30].map -> [ 0, 0 ]
        # Stats; totals for periods.
        stats =
            today:      [ 0, 0 ]
            lastToday:  [ 0, 0 ]
            week:       [ 0, 0 ]
            lastWeek:   [ 0, 0 ]
            month:      [ 0, 0 ]
            lastMonth:  [ 0, 0 ]

        # Stream it.
        messages response, (collection) ->
            stream = collection.find(
                'key': user.client_key
            ,
                'sort': [ [ "timestamp", "desc" ] ]
            ).streamRecords()
            
            stream.on "data", (message) ->
                # Save to log.
                log.push message

                # What type?
                type = (message.type is 'message') + 0

                # Position in stats.
                if message.timestamp > today # today
                    stats.today[type] += message.count
                    stats.week[type] += message.count
                    stats.month[type] += message.count

                    if message.type is 'exception' then exceptions.push message
                
                else if message.timestamp > today - 8.64e7 # yesterday
                    stats.lastToday[type] += message.count
                    stats.week[type] += message.count
                    stats.month[type] += message.count

                    if message.type is 'exception' then exceptions.push message

                else if message.timestamp > today - 6.048e8 # this week
                    stats.week[type] += message.count
                    stats.month[type] += message.count

                    if message.type is 'exception' then exceptions.push message

                else if message.timestamp > today - 1.2096e9 # last week
                    stats.lastWeek[type] += message.count
                    stats.month[type] += message.count

                else if message.timestamp > today - 2.592e9 # this month (assume 30)
                    stats.month[type] += message.count
                
                else if message.timestamp > today - 5.184e9 # last month (assume 30)
                    stats.lastMonth[type] += message.count

                # And also position it in the chart.
                idx = Math.floor((today + 8.64e7 - message.timestamp) / 8.64e7)
                chart[idx]?[type] += message.count

            stream.on "end", ->
                # Custom sort exceptions.
                sortBy = (key, a, b, r) ->
                    r = if r then 1 else -1
                    return -1*r if a[key] > b[key]
                    return +1*r if a[key] < b[key]
                    return 0

                sortByMultiple = (a, b, keys) ->
                    return r if (r = sortBy key, a, b) for key in keys
                    return 0

                exceptions.sort (a, b) -> sortByMultiple a, b, ['browser', 'url', 'line', 'body']

                render request, response, 'dashboard',
                    'log':        log
                    'stats':      stats
                    'chart':      chart
                    'exceptions': exceptions

# Receive message.
router.get '/message', (request, response) ->
    message = urlib.parse(request.url, true).query
    message.timestamp = new Date().getTime()
    message.count = 1
    message.browser = ua.parse(request.headers['user-agent']).family.toLowerCase()

    # Set MIME to an image.
    response.writeHead 200,
        "Content-Type":   "image/png"
        "Content-Length": 0

    messages response, (collection) ->
        # Update an existing message from upto an hour ago...
        collection.findAndModify
            'timestamp':
                '$gt': message.timestamp - 3.6e6
            'url':     message.url
            'type':    message.type
            'body':    message.body
            'line':    message.line
            'browser': message.browser
            'key':     message.key
        , [ ],
            '$inc':
                'count': 1
        , {}, (err, object) ->
            # ...or make a new record if possible.
            collection.insert message unless object?
            response.end()

# Delete a message.
router.get '/delete', (request, response) ->
    die = ->
        response.writeHead 400
        response.end()

    message = (urlib.parse(request.url, true).query)?.message

    if not message? or message.length is 0 then die()

    # Authorize.
    authorize request, response, (user) ->

        # A good message id?
        try
            id = mongodb.ObjectID.createFromHexString message
        catch err
            return die()

        # Now maybe remove the message in question provided it exists and we are associated with it.
        messages response, (collection) ->
            collection.remove
                '_id': id
                'key': user.client_key
            
            # Redir to index.
            response.writeHead 302,
                Location: "http://#{host}/"
            response.end()

# Documentation.
router.get '/documentation', (request, response) ->
    authorize request, response, (user) ->
        render request, response, 'documentation',
            'user': user
            'host': host

# Logout.
router.get '/logout', (request, response) ->
    response.writeHead 200,
      'Set-Cookie':   "mistok_app=null;path=/;domain=#{host.split(':')[0]};expires=#{new Date().toUTCString()}"
      'Content-Type': 'text/plain'
    response.end()

# -------------------------------------------------------------------
# User authorization.
authorize = (request, response, callback) ->
    redirect = ->
        response.writeHead 302,
            Location: '/openid/authenticate'
        response.end()

    cookie = do ->
        if cookies = request.headers.cookie
            for cookie in cookies.replace(/\s/g, '').split ';'
                [key, value] = cookie.split '='
                # Has cookie?
                if key is 'mistok_app' then return value

    # A cookie?
    if cookie?
        # A worthy cookie?
        try
            id = mongodb.ObjectID.createFromHexString cookie
        catch err
            return redirect()

        # A valid cookie?
        users response, (collection) ->
            collection.findOne
                '_id': id
            , (err, user) ->
                return redirect() if err or not user

                console.log "User #{cookie} authorized".yellow
                callback user
    
    else redirect()

# -------------------------------------------------------------------
# OpenID authentication.
relying = new openid.RelyingParty "http://#{host}/openid/verify", "http://#{host}/", false, false, []
router.get '/openid/authenticate', (request, response) ->
    relying.authenticate 'http://www.google.com/accounts/o8/id', false, (error, authUrl) ->
        if error
            response.writeHead 200
            response.end "Authentication failed: " + error.message
        else unless authUrl
            response.writeHead 200
            response.end "Authentication failed"
        else
            response.writeHead 302,
                Location: authUrl
            response.end()

router.get '/openid/verify', (request, response) ->
    relying.verifyAssertion request, (error, result) ->
        response.writeHead 200
        if not error and result.authenticated
            identity = result.claimedIdentifier.split('=').pop()
            console.log "OpenID identity #{identity}".yellow

            # Save user cookie.
            saveCookie = (key, response) ->
                console.log "User #{key} authenticated".yellow

                response.writeHead 200,
                  'Set-Cookie':   "mistok_app=#{key};path=/;domain=#{host.split(':')[0]}"
                  'Content-Type': 'text/html'

                # Redir using JavaScript to the dashboard.
                response.end "<script>window.location='http://#{host}/'</script>"

            # Do we already have this user?
            users response, (collection) ->
                collection.findOne
                    'identity': identity
                , (err, user) ->
                    if err or not user
                        # Insert new user.
                        collection.insert
                            'identity':   identity
                            'client_key': "#{hex()}-#{hex()}-#{hex()}"
                        ,
                            'safe': true
                        , (err, saved) ->
                            return log err, response if err or not saved

                            saveCookie saved, response
                    else
                        # We have a user. Cookie their key.
                        saveCookie user._id, response

        else response.end()

# -------------------------------------------------------------------
# Eco template rendering and helpers.
render = (request, response, filename, data={}) ->
    fs.readFile "./server/templates/#{filename}.eco", "utf8", (err, template) ->
        return log err, response if err

        resource = eco.render template, data
        response.writeHead 200,
            'Content-Type':  'text/html'
            'Content-Length': resource.length
        response.write resource
        response.end()

Date::pretty = ->
    diff = new Date().getTime() - @.getTime()
    day = Math.floor(diff / 8.64e7)
    return '?' if isNaN(day) or day < 0 or day >= 31
    if day is 0
        if diff < 6e4 then "Just now"
        else if diff < 1.2e5 then "A minute ago"
        else if diff < 3.6e6 then "#{Math.floor(diff / 6e4)} minutes ago"
        else if diff < 7.2e6 then "An hour ago"
        else "#{Math.floor(diff / 3.6e6)} hours ago"
    else
        if day is 1 then "Yesterday"
        else if day < 7 then "#{day} days ago"
        else "#{Math.ceil(day / 7)} weeks ago"

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
# Error 404 logging.
log = (error, response) ->
    console.log new String(error.message).red
    response.writeHead 404
    response.end()

# -------------------------------------------------------------------
# Main routing.
server = http.createServer (request, response) ->

    url = request.url.toLowerCase()

    if request.method is 'GET'
        route = router.routes[url.split('?')[0]]
        if route
            console.log "#{request.method} #{url}".bold
            route request, response
        else
            # Public resource?
            console.log "#{request.method} #{url}".grey

            file = "./server#{url}"
            # LESS?
            if file[-9...] is '.less.css'
                css request, response, file.replace('.less.css', '.less')
            else
                fs.stat file, (err, stat) ->
                    if err
                        # 404.
                        console.log "#{url} not found".red
                        response.writeHead 404
                        response.end()
                    else
                        # Cache control.
                        mtime = stat.mtime
                        etag = stat.size + '-' + Date.parse(mtime)
                        response.setHeader('Last-Modified', mtime);

                        if request.headers['if-none-match'] is etag
                            response.statusCode = 304
                            response.end()
                        else
                            # Stream file.
                            response.writeHead 200,
                                'Content-Type':   mime.lookup file
                                'Content-Length': stat.size
                                'ETag':           etag

                            util.pump fs.createReadStream(file), response, (err) ->
                                return log err, response if err
    
    else log { 'message': 'No matching route' }, response

# -------------------------------------------------------------------
# Database helpers.
hex = -> (((1 + Math.random()) * 0x10000) | 0).toString(16).substring 1

messages = (response, cb) -> db.collection 'messages', (err, collection) ->
    return log err, response if err
    cb collection

users = (response, cb) -> db.collection 'users', (err, collection) ->
    return log err, response if err
    cb collection

# -------------------------------------------------------------------
# Fire up the server.
startup = ->
    # Fire up the server.
    server.listen port
    console.log "Listening on port #{port}".green.bold