// Generated by CoffeeScript 1.3.3
(function() {
  var $, Mistok;

  $ = window.jQuery || window.Zepto;

  Mistok = (function() {

    Mistok.prototype.log = function(obj, callback) {
      var _ref;
      if (this.server == null) {
        throw 'Please set the location of the server.';
      }
      if (typeof obj === "string") {
        obj = {
          type: 'message',
          body: obj
        };
      }
      if (!((obj.type != null) || (obj.body != null))) {
        throw "Make sure the object meets the form: { type:'', body:'' }";
      }
      if (this.key == null) {
        throw 'Please set your client key.';
      }
      obj.key = this.key;
      obj.url = (_ref = obj.url) != null ? _ref : document.URL;
      return $.ajax({
        url: "" + this.server + "/message",
        data: obj,
        dataType: 'jsonp',
        statusCode: {
          404: function() {
            if (callback) {
              return callback(404);
            }
          },
          200: function() {
            if (callback) {
              return callback(200);
            }
          }
        }
      });
    };

    function Mistok() {
      var _this = this;
      window.onerror = function(msg, url, line) {
        var data;
        data = {
          type: 'exception',
          body: msg != null ? msg : 'No message'
        };
        data.url = url != null ? url : '';
        data.line = line != null ? line : '';
        return _this.log(data);
      };
    }

    return Mistok;

  })();

  window.Mistok = new Mistok();

}).call(this);
