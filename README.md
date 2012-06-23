# Mistök

Monitor your client-side JavaScript. Detect exceptions and log messages.

![image](https://raw.github.com/radekstepan/mistok/master/example.png)

## Requirements:

### Client:

None.

### Server:

You can install all dependencies by running:

```bash
npm install coffee-script -g
npm install -d
```

1. [coffee-script](http://coffeescript.org).
2. `fs` (node stdlib) for reading in files.
3. `url` (node stdlib) for parsing request params.
4. `http` (node stdlib) for listening to your request-y music.
5. `util` (node stdlib) for pump streaming files.
6. [eco](https://github.com/sstephenson/eco) for embedding CoffeeScript in HTML templates.
7. [less](http://http://lesscss.org) for extending CSS with mixins, variables, functions and the like.
8. [tiny](https://github.com/chjj/node-tiny) for storing data in a flat file.
9. [openid](https://github.com/havard/node-openid) for a working OpenID client implementation.
10. [mime](https://github.com/bentomas/node-mime) for comprehensive MIME type mapping.
11. [ua-parser](https://github.com/tobie/ua-parser) for determining User-Agent server side.
12. [colors](https://github.com/Marak/colors.js) for getting colors in node console.

## Use:

### Client:

Point to the client script and set it up with your key and server.

```html
<script src="http://127.0.0.1:1116/js/mistok.js"></script>
<script>
    Mistok.key = 'CCB4-7AEB-71BD';
    Mistok.server = 'http://127.0.0.1:1116';
</script>
```

To trigger a custom message do the following:

```html
<script>
    Mistok.log('Test message');
</script>
```

### Server:

Configure the `port` and `host` vars in `server/server.coffee`, they are setup for local development:

```javascript
host = '127.0.0.1:1116'
port = 1116
```

Start the app:

```bash
./server.sh
```

#### Notes:

1. Expects you to use **Google OpenID auth** automatically creating an account for you on the server upon authentication.
2. Uses flat file databases.
3. Uses custom NIH web server.
4. When specifying the host, `127.0.0.1` or `0.0.0.0` does not work on Opera while `localhost` does not work in Chrome.
