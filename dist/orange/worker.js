(function() {
  var Job;

  Job = (function() {
    var respond;

    respond = function(type, response) {
      return self.postMessage({
        type: type,
        response: response
      });
    };

    function Job(context) {
      this.context = context;
      this._subscriptions = {};
      this._done = false;
    }

    Job.prototype.on = function(event, callback) {
      if (this._subscriptions[event] == null) {
        this._subscriptions[event] = [];
      }
      return this._subscriptions[event].push(callback);
    };

    Job.prototype.done = function(data) {
      respond('success', data);
      return this._done = true;
    };

    Job.prototype.isDone = function() {
      return this._done;
    };

    Job.prototype.error = function(error) {
      return respond('error', error);
    };

    Job.prototype.trigger = function(event, data) {
      return respond(event, data);
    };

    Job.prototype.log = function(message) {
      return respond("log", message);
    };

    return Job;

  })();

  this.perform = function(handler) {
    var job;
    job = new Job;
    return self.onmessage = function(e) {
      var callback, data, result, subcriptions, type, _i, _len, _ref, _results;
      _ref = e.data, type = _ref.type, data = _ref.data;
      if (type === 'perform') {
        if ((result = handler(job, data)) && !job.isDone()) {
          return job.done(result);
        }
      } else if (job._subscriptions[type] != null) {
        subcriptions = job._subscriptions[type];
        _results = [];
        for (_i = 0, _len = subcriptions.length; _i < _len; _i++) {
          callback = subcriptions[_i];
          _results.push(callback(data));
        }
        return _results;
      }
    };
  };

}).call(this);

/*
//@ sourceMappingURL=worker.js.map
*/