# Mistök

Monitor your client-side JavaScript. Detect exceptions and log messages.

![image](https://raw.github.com/radekstepan/mistok/master/example.png)

## Requirements:

### Client:

* [jQuery](http://jquery.com/) as we use `$.ajax` and `$.browser`.

### Server:

You can install all dependencies by running:

```bash
npm install coffee-script
npm install -d
```

1. [coffeescript](http://coffeescript.org).
2. `fs` (node stdlib) for reading in files.
3. `url` (node stdlib) for parsing request params.
4. `http` (node stdlib) for listening to your request-y music.
5. `util` (node stdlib) for pump streaming files.
6. [eco](https://github.com/sstephenson/eco) for embedding CoffeeScript in HTML templates.
7. [less](http://http://lesscss.org) for extending CSS with mixins, variables, functions and the like.
8. [tiny](https://github.com/chjj/node-tiny) for storing data in a flat file.
9. [openid](https://github.com/havard/node-openid) for a working OpenID client implementation.
10. [mime](https://github.com/bentomas/node-mime) for comprehensive MIME type mapping.
11. [colors](https://github.com/Marak/colors.js) for getting colors in node console.

## Use:

### Client:

Point to the client script and set it up with your key and server.

```html
<script src="http://mistok.app:1116/js/mistok.js"></script>
<script>
    Mistok.key = 'CCB4-7AEB-71BD';
    Mistok.server = 'http://mistok.app:1116';
</script>
```

To trigger a custom message do the following:

```html
<script>
    Mistok.log('Test message', function(code) {
        // HTTP code of the response (either 200 or 404)
    });
</script>
```

### Server:

Configure the `port` and `host` vars in `server/server.coffee`, they are setup for local development:

```javascript
host = 'mistok.app:1116'
port = 1116
```

Start the app:

```bash
./server.sh
```