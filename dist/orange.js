/*
orange - v0.2.0 - 2014-02-07
http://github.com/polarblau/orange
Copyright (c) 2014 Florian Plank
Licensed MIT
*/


(function() {
  var BatchStateTransitionError, JobStateTransitionError, ResponderNotFoundError, SchedulerSingleton,
    __slice = [].slice,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  (function() {
    var browserRaf, canceled, targetTime, vendor, w, _i, _len, _ref;
    w = window;
    _ref = ['ms', 'moz', 'webkit', 'o'];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      vendor = _ref[_i];
      if (w.requestAnimationFrame) {
        break;
      }
      w.requestAnimationFrame = w["" + vendor + "RequestAnimationFrame"];
      w.cancelAnimationFrame = w["" + vendor + "CancelAnimationFrame"] || w["" + vendor + "CancelRequestAnimationFrame"];
    }
    if (w.requestAnimationFrame) {
      if (w.cancelAnimationFrame) {
        return;
      }
      browserRaf = w.requestAnimationFrame;
      canceled = {};
      w.requestAnimationFrame = function(callback) {
        var id;
        return id = browserRaf(function(time) {
          if (id in canceled) {
            return delete canceled[id];
          } else {
            return callback(time);
          }
        });
      };
      return w.cancelAnimationFrame = function(id) {
        return canceled[id] = true;
      };
    } else {
      targetTime = 0;
      w.requestAnimationFrame = function(callback) {
        var currentTime;
        targetTime = Math.max(targetTime + 16, currentTime = +(new Date));
        return w.setTimeout((function() {
          return callback(+(new Date));
        }), targetTime - currentTime);
      };
      return w.cancelAnimationFrame = function(id) {
        return clearTimeout(id);
      };
    }
  })();

  window.Orange = {};

  /* test-only-> */;

  Orange.__testOnly__ = {};

  /* <-test-only */;

  if ('Worker' in window) {
    Orange.Worker = Worker;
  } else {
    throw new Error('Your environment does not support WebWorkers');
  }

  Orange.Utils = {
    log: function() {
      var args, _ref;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return typeof console !== "undefined" && console !== null ? (_ref = console.log) != null ? _ref.apply(console, args) : void 0 : void 0;
    },
    underscore: function(string) {
      return string.replace(/([A-Z])/g, function($1) {
        return "_" + $1.toLowerCase();
      });
    },
    webWorkerPathFor: function(type) {
      var path;
      path = Orange.Config.get('workersPath');
      return [path, "" + (this.underscore(type)) + ".js"].join('/').replace(/\/{2,}/, '/');
    }
  };

  Orange.Eventable = (function() {
    function Eventable() {
      this.trigger = __bind(this.trigger, this);
      this.off = __bind(this.off, this);
      this.on = __bind(this.on, this);
      this._subscriptions = {};
    }

    Eventable.prototype.on = function(event, callback) {
      if (this._subscriptions[event] == null) {
        this._subscriptions[event] = [];
      }
      return this._subscriptions[event].push(callback);
    };

    Eventable.prototype.off = function(event, callback) {
      var cb, e, subscriptions, _ref;
      if (this._subscriptions[event] != null) {
        if (callback != null) {
          return this._subscriptions[event] = (function() {
            var _i, _len, _ref, _results;
            _ref = this._subscriptions[event];
            _results = [];
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              cb = _ref[_i];
              if (cb !== callback) {
                _results.push(cb);
              }
            }
            return _results;
          }).call(this);
        } else {
          subscriptions = [];
          _ref = this._subscriptions;
          for (e in _ref) {
            cb = _ref[e];
            if (e !== event) {
              subscriptions[e] = cb;
            }
          }
          return this._subscriptions = subscriptions;
        }
      }
    };

    Eventable.prototype.trigger = function(event, data) {
      var callback, subcriptions, _i, _len, _results;
      if (this._subscriptions[event] != null) {
        subcriptions = this._subscriptions[event];
        _results = [];
        for (_i = 0, _len = subcriptions.length; _i < _len; _i++) {
          callback = subcriptions[_i];
          _results.push(callback.call(this, data));
        }
        return _results;
      }
    };

    return Eventable;

  })();

  (function(Orange) {
    var DEFAULTS, settings;
    DEFAULTS = {
      maxWorkerPoolSize: 4,
      maxRetries: 3,
      workersPath: '/lib/workers/'
    };
    settings = DEFAULTS;
    return Orange.Config = {
      set: function(key, value) {
        var k, v, _results;
        if (value != null) {
          if (settings[key] != null) {
            return settings[key] = value;
          }
        } else {
          _results = [];
          for (k in key) {
            v = key[k];
            if (settings[k] != null) {
              _results.push(settings[k] = v);
            }
          }
          return _results;
        }
      },
      get: function(key) {
        if (key != null) {
          return settings[key];
        } else {
          return settings;
        }
      }
    };
  })(Orange);

  (function(Orange) {
    var jobs, length;
    jobs = [];
    length = 0;
    return Orange.Queue = {
      push: function(job) {
        jobs.push(job);
        return length = jobs.length;
      },
      getLength: function() {
        return length;
      },
      shift: function() {
        var job;
        job = jobs.shift();
        length = jobs.length;
        return job;
      },
      isEmpty: function() {
        return this.getLength() <= 0;
      },
      reset: function() {
        jobs = [];
        return length = jobs.length;
      }
    };
  })(Orange);

  JobStateTransitionError = (function(_super) {
    __extends(JobStateTransitionError, _super);

    JobStateTransitionError.prototype.name = 'JobStateTransitionError';

    function JobStateTransitionError() {
      this.message = "Can't execute #perform multiple times on same job.";
    }

    return JobStateTransitionError;

  })(Error);

  Orange.Job = (function(_super) {
    __extends(Job, _super);

    function Job(_type, _data, _keepAlive) {
      this._type = _type;
      this._data = _data;
      this._keepAlive = _keepAlive != null ? _keepAlive : false;
      this.handleSuccess = __bind(this.handleSuccess, this);
      this.handleError = __bind(this.handleError, this);
      this.terminate = __bind(this.terminate, this);
      this.perform = __bind(this.perform, this);
      this._retryCount = 0;
      this._isLocked = false;
      this._response = null;
      this._lastError = null;
      Job.__super__.constructor.call(this);
    }

    Job.prototype.perform = function(isRetry) {
      if (isRetry == null) {
        isRetry = false;
      }
      if (this.isLocked() && !isRetry) {
        throw new JobStateTransitionError;
      } else {
        this.lock();
        Orange.Queue.push(this);
      }
      return this;
    };

    Job.prototype.terminate = function() {
      if (this.isKeepAlive()) {
        return this.trigger('terminate');
      }
    };

    Job.prototype.handleError = function(error) {
      this._lastError = error;
      if (this._retryCount < Orange.Config.get('maxRetries')) {
        this.scheduleRetry();
        return this.trigger('error', error);
      } else {
        this.trigger('error', error);
        this.trigger('failure', error);
        return this.trigger('complete');
      }
    };

    Job.prototype.handleSuccess = function(response) {
      this._response = response;
      this.trigger('complete');
      return this.trigger('success', response);
    };

    Job.prototype.handleEvent = function(type, response) {
      return this.trigger(type, response);
    };

    Job.prototype.lock = function() {
      return this._isLocked = true;
    };

    Job.prototype.isLocked = function() {
      return this._isLocked;
    };

    Job.prototype.isKeepAlive = function() {
      return this._keepAlive;
    };

    Job.prototype.getType = function() {
      return this._type;
    };

    Job.prototype.getData = function() {
      return this._data;
    };

    Job.prototype.getResponse = function() {
      return this._response;
    };

    Job.prototype.getLastError = function() {
      return this._lastError;
    };

    Job.prototype.scheduleRetry = function() {
      var offset;
      this._retryCount++;
      offset = Math.pow(this._retryCount, 2) * 1000;
      return setTimeout(this.perform, offset, true);
    };

    return Job;

  })(Orange.Eventable);

  BatchStateTransitionError = (function(_super) {
    __extends(BatchStateTransitionError, _super);

    BatchStateTransitionError.prototype.name = 'BatchStateTransitionError';

    function BatchStateTransitionError() {
      this.message = "Can't execute #perform multiple times on same batch.";
    }

    return BatchStateTransitionError;

  })(Error);

  Orange.Batch = (function(_super) {
    __extends(Batch, _super);

    function Batch(jobs) {
      var job, _i, _len;
      if (jobs == null) {
        jobs = [];
      }
      this._onJobCompleted = __bind(this._onJobCompleted, this);
      this._enableEventdispatch = __bind(this._enableEventdispatch, this);
      this.jobs = [];
      this._completedJobsCount = 0;
      this._isLocked = false;
      for (_i = 0, _len = jobs.length; _i < _len; _i++) {
        job = jobs[_i];
        this.push(job);
      }
      Batch.__super__.constructor.call(this);
    }

    Batch.prototype.push = function(job) {
      job.on('complete', this._onJobCompleted);
      return this.jobs.push(job);
    };

    Batch.prototype.perform = function() {
      var job, _i, _len, _ref, _results;
      if (this.isLocked()) {
        throw new BatchStateTransitionError;
      } else {
        this.lock();
        this._enableEventdispatch();
        _ref = this.jobs;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          job = _ref[_i];
          _results.push(job.perform());
        }
        return _results;
      }
    };

    Batch.prototype.lock = function() {
      return this._isLocked = true;
    };

    Batch.prototype.isLocked = function() {
      return this._isLocked;
    };

    Batch.prototype._enableEventdispatch = function() {
      var batch, job, _i, _len, _ref, _results;
      _ref = this.jobs;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        job = _ref[_i];
        batch = this;
        job.on('complete', function() {
          return batch.trigger('job:complete', this);
        });
        job.on('success', function() {
          return batch.trigger('job:success', this);
        });
        job.on('error', function() {
          return batch.trigger('job:error', this);
        });
        _results.push(job.on('failure', function() {
          return batch.trigger('job:failure', this);
        }));
      }
      return _results;
    };

    Batch.prototype._onJobCompleted = function() {
      if (++this._completedJobsCount >= this.jobs.length) {
        return this.trigger('complete', this.jobs);
      }
    };

    return Batch;

  })(Orange.Eventable);

  ResponderNotFoundError = (function(_super) {
    __extends(ResponderNotFoundError, _super);

    ResponderNotFoundError.prototype.name = 'MethodNotFoundError';

    function ResponderNotFoundError(type) {
      this.message = "Orange.Worker does't respond to method #" + type;
    }

    return ResponderNotFoundError;

  })(Error);

  Orange.Thread = (function(_super) {
    __extends(Thread, _super);

    function Thread(job) {
      var path, type;
      this.job = job;
      this.onError = __bind(this.onError, this);
      this.onMessage = __bind(this.onMessage, this);
      this.kill = __bind(this.kill, this);
      type = this.job.getType();
      path = Orange.Utils.webWorkerPathFor(type);
      if (this.job.isKeepAlive()) {
        this.job.on('terminate', this.kill);
      }
      this.webWorker = new Orange.Worker(path);
      this.webWorker.onmessage = this.onMessage;
      this.webWorker.onerror = this.onError;
      Thread.__super__.constructor.call(this);
    }

    Thread.prototype.perform = function() {
      return this.webWorker.postMessage({
        type: 'perform',
        data: this.job.getData()
      });
    };

    Thread.prototype.kill = function() {
      this.webWorker.terminate();
      return this.webWorker = null;
    };

    Thread.prototype.onMessage = function(message) {
      var response, type, _ref;
      _ref = message.data, type = _ref.type, response = _ref.response;
      if (this.responders[type] != null) {
        this.responders[type].call(this, response);
        if (!this.job.isKeepAlive()) {
          return this.trigger('done');
        }
      } else {
        return this.job.handleEvent(type, response);
      }
    };

    Thread.prototype.onError = function(error) {
      this.responders.error.call(this, error);
      this.trigger('done');
      return error.preventDefault();
    };

    Thread.prototype.responders = {
      error: function(error) {
        return this.job.handleError(error);
      },
      success: function(response) {
        return this.job.handleSuccess(response);
      },
      stream: function(response) {
        return this.job.handleStream(response);
      },
      log: function(message) {
        return Orange.Utils.log(message);
      }
    };

    /* test-only-> */;

    Orange.__testOnly__.Thread = Thread;

    /* <-test-only */;

    return Thread;

  })(Orange.Eventable);

  SchedulerSingleton = (function() {
    var Scheduler, instance, poolSize;

    function SchedulerSingleton() {}

    instance = null;

    poolSize = 0;

    Scheduler = (function() {
      var addThreadToPool, removeThreadFromPool;

      function Scheduler() {
        this.update = __bind(this.update, this);
      }

      Scheduler.prototype.tick = function() {
        return requestAnimationFrame(this.update);
      };

      Scheduler.prototype.update = function() {
        var job, thread;
        if (!(Orange.Queue.isEmpty() || this.poolIsFull())) {
          job = Orange.Queue.shift();
          thread = new Orange.Thread(job);
          thread.on('done', function() {
            return removeThreadFromPool(thread);
          });
          addThreadToPool(thread);
        }
        return this.tick();
      };

      Scheduler.prototype.poolIsFull = function() {
        return poolSize >= Orange.Config.get('maxWorkerPoolSize');
      };

      addThreadToPool = function(thread) {
        poolSize++;
        return thread.perform();
      };

      removeThreadFromPool = function(thread) {
        poolSize--;
        thread.kill();
        return thread = null;
      };

      return Scheduler;

    })();

    SchedulerSingleton.getInstance = function() {
      return instance != null ? instance : instance = new Scheduler;
    };

    return SchedulerSingleton;

  }).call(this);

  SchedulerSingleton.getInstance().tick();

}).call(this);

/*
//@ sourceMappingURL=orange.js.map
*/