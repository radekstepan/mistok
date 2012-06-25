# Mistök

Monitor your client-side JavaScript. Detect exceptions and log messages.

![image](https://raw.github.com/radekstepan/mistok/master/example.png)

## Requirements:

### Client:

None.

### Server:

You can install all dependencies by running:

```bash
$ npm install -d
```

1. [coffee-script](http://coffeescript.org).
2. `fs` (node stdlib) for reading in files.
3. `url` (node stdlib) for parsing request params.
4. `http` (node stdlib) for listening to your request-y music.
5. `util` (node stdlib) for pump streaming files.
6. [mongodb](http://mongodb.github.com/node-mongodb-native) a MongoDB driver.
7. [eco](https://github.com/sstephenson/eco) for embedding CoffeeScript in HTML templates.
8. [less](http://http://lesscss.org) for extending CSS with mixins, variables, functions and the like.
9. [openid](https://github.com/havard/node-openid) for a working OpenID client implementation.
10. [mime](https://github.com/bentomas/node-mime) for comprehensive MIME type mapping.
11. [ua-parser](https://github.com/tobie/ua-parser) for determining User-Agent server side.
12. [colors](https://github.com/Marak/colors.js) for getting colors in node console.

## Use:

### Client:

Point to the client script and set it up with your key and server.

```html
<script src="http://mistok.herokuapp.com/js/mistok.js"></script>
<script>
    Mistok.key = '[YOUR_KEY]';
    Mistok.server = 'http://mistok.herokuapp.com';
</script>
```

To trigger a custom message do the following:

```html
<script>
    Mistok.log('Test message');
</script>
```

### Database:

Install the [MongoDB](http://www.mongodb.org/downloads) driver appropriate for your OS. Then create a space for the db and start the process:

```bash
$ mkdir /data/db
$ ./mongod
```

Deploying locally, the server expects to find the database at `localhost:27017`, the default.

### Server:

Configure the `port` and `host` vars in `server/server.coffee`, they are setup for [Heroku](http://heroku.com) deployment now:

```javascript
port = process.env.PORT or 1116
host = 'mistok.herokuapp.com'
```

Start the server app (making sure CoffeeScript is in your PATH):

```bash
$ coffee server/server.coffee
```

### Heroku:

For [Heroku](http://heroku.com) deployment, make sure you have an account.

Login to Heroku providing email and password:

```bash
$ heroku login
```

Create the app if does not exist already in your account:

```bash
$ heroku create
```

Set environment variables, like:

```bash
$ heroku config:add MONGOHQ_USER=[YOUR_USERNAME] MONGOHQ_PASSWORD=[YOUR_PASSWORD]
```

Deploy your code:

```bash
$ git push heroku master
```

Check the app is running:

```bash
$ heroku ps
```

If not, see the logs:

```bash
$ heroku logs
```

To login to the console:

```bash
$ heroku run bash
```

If you need to rename the app:

```bash
$ git remote rm heroku
$ git remote add heroku git@heroku.com:yourappname.git
```

Bear in mind that the `Procfile` specifies a shell script to run, as we need to add the CoffeeScript compiler to the PATH first. We also make use of the `process.env.PORT` specified by Heroku that is used internally only.

#### Notes:

1. Expects you to use **Google OpenID auth** automatically creating an account for you on the server upon authentication.
3. Uses custom NIH web server.
4. When specifying the host, `127.0.0.1` or `0.0.0.0` does not work on Opera while `localhost` does not work in Chrome.