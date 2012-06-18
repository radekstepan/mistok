// Generated by CoffeeScript 1.3.1
(function() {
  var $, Mistok;

  $ = window.jQuery || window.Zepto;

  Mistok = (function() {

    Mistok.name = 'Mistok';

    Mistok.prototype.log = function(obj) {
      var _ref;
      if (typeof obj === "string") {
        obj = {
          type: "Message",
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
      return $.ajax({
        url: 'http://0.0.0.0:1116/message',
        data: obj,
        dataType: 'jsonp',
        success: function(data) {
          return console.log("success");
        },
        error: function(request, status, error) {}
      });
    };

    function Mistok() {
      var _this = this;
      window.onerror = function(msg, url, lineno) {
        var data;
        data = {
          type: 'Exception',
          body: msg != null ? msg : 'No message'
        };
        data.url = url != null ? url : '';
        data.lineno = lineno != null ? lineno : '';
        return Mistok.log(data);
      };
    }

    return Mistok;

  })();

  window.Mistok = new Mistok();

}).call(this);
