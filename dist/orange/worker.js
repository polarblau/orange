(function() {
  var MethodNotFoundError, respond,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  MethodNotFoundError = (function(_super) {
    __extends(MethodNotFoundError, _super);

    MethodNotFoundError.prototype.name = 'MethodNotFoundError';

    function MethodNotFoundError(method) {
      this.message = "Worker does't implement method #" + method;
    }

    return MethodNotFoundError;

  })(Error);

  this.perform = function(handler) {
    var wrappedPerform;
    wrappedPerform = function(data) {
      var response;
      response = handler(data);
      return respond('success', response);
    };
    return self.onmessage = function(e) {
      var data, type, _ref;
      _ref = e.data, type = _ref.type, data = _ref.data;
      if (type === 'perform') {
        return wrappedPerform(data);
      } else {
        throw new MethodNotFoundError(type);
      }
    };
  };

  this.log = function(message) {
    return respond("log", message);
  };

  respond = function(type, response) {
    return self.postMessage({
      type: type,
      response: response
    });
  };

}).call(this);

/*
//@ sourceMappingURL=worker.js.map
*/