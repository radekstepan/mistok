// Generated by CoffeeScript 1.3.1
(function() {
  var $, Mistok;

  $ = window.jQuery || window.Zepto;

  Mistok = (function() {

    Mistok.name = 'Mistok';

    Mistok.prototype.log = function(obj, callback) {
      var _ref;
      if (typeof obj === "string") {
        obj = {
          type: 'message',
          body: obj
        };
      }
      if (obj.type === 'undefined' || obj.body === 'undefined') {
        throw "Make sure the object meets the form: { type:'', body:'' }";
      }
      if (this.key === void 0) {
        throw 'Please set your API key.';
      }
      obj.key = this.key;
      obj.url = (_ref = obj.url) != null ? _ref : document.URL;
      obj.browser = this.browser;
      return $.ajax({
        url: 'http://0.0.0.0:1116/message',
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
      this.browser = (function() {
        if ($.browser.webkit) {
          if (!!window.chrome) {
            return 'chrome';
          } else {
            return 'safari';
          }
        } else if ($.browser.firefox || $.browser.mozilla) {
          return 'firefox';
        } else if ($.browser.msie) {
          return 'explorer';
        } else if ($.browser.opera) {
          return 'opera';
        } else {
          return 'unknown';
        }
      })();
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
