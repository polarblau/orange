(function() {
  var Dummy,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  describe('Config', function() {
    var DEFAULTS;
    DEFAULTS = {
      maxWorkerPoolSize: 4,
      maxRetries: 3,
      workersPath: '/lib/workers/'
    };
    beforeEach(function() {
      return Orange.Config.set(DEFAULTS);
    });
    describe('#get', function() {
      describe('when called without arguments', function() {
        it('should return an object', function() {
          return expect(Orange.Config.get()).to.be.a('object');
        });
        return it('should return the defaults', function() {
          return expect(Orange.Config.get()).to.eql(DEFAULTS);
        });
      });
      return describe('when called with key', function() {
        return it('should return the settings value', function() {
          return expect(Orange.Config.get('maxRetries')).to.equal(DEFAULTS.maxRetries);
        });
      });
    });
    describe('#set', function() {
      describe('when called with two arguments', function() {
        it('should set a key/value pair', function() {
          Orange.Config.set('maxRetries', 10);
          return expect(Orange.Config.get('maxRetries')).to.equal(10);
        });
        return it('should not set an non existant key', function() {
          Orange.Config.set('foo', 'bar');
          return expect(Orange.Config.get('foo')).to.not.exist;
        });
      });
      return describe('when called with a hash (object)', function() {
        it('should set all pairs in the hash', function() {
          Orange.Config.set({
            maxWorkerPoolSize: 10,
            maxRetries: 12
          });
          expect(Orange.Config.get('maxWorkerPoolSize')).to.be.equal(10);
          return expect(Orange.Config.get('maxRetries')).to.equal(12);
        });
        return it('should not set an non existant key', function() {
          Orange.Config.set({
            maxWorkerPoolSize: 10,
            foo: 'bar'
          });
          expect(Orange.Config.get('maxWorkerPoolSize')).to.equal(10);
          return expect(Orange.Config.get('foo')).to.not.exist;
        });
      });
    });
    return describe('defaults', function() {
      return it('should return defaults when nothing set', function() {
        return expect(Orange.Config.get()).to.eql(DEFAULTS);
      });
    });
  });

  Dummy = (function(_super) {
    __extends(Dummy, _super);

    function Dummy() {
      Dummy.__super__.constructor.call(this);
    }

    return Dummy;

  })(Orange.Eventable);

  describe('Eventable', function() {
    beforeEach(function() {
      return this.dummy = new Dummy;
    });
    describe('#on', function() {
      it('should bind an event with a callback', function() {
        var callback;
        callback = sinon.spy();
        this.dummy.on('foo', callback);
        this.dummy.trigger('foo');
        return expect(callback).to.have.been.called;
      });
      it('should bind multiple events', function() {
        var callback1, callback2;
        callback1 = sinon.spy();
        callback2 = sinon.spy();
        this.dummy.on('foo', callback1);
        this.dummy.on('bar', callback2);
        this.dummy.trigger('foo');
        this.dummy.trigger('bar');
        expect(callback1).to.have.been.called;
        return expect(callback2).to.have.been.called;
      });
      it('should bind to the same event multiple times', function() {
        var callback1, callback2;
        callback1 = sinon.spy();
        callback2 = sinon.spy();
        this.dummy.on('foo', callback1);
        this.dummy.on('foo', callback2);
        this.dummy.trigger('foo');
        expect(callback1).to.have.been.called;
        return expect(callback2).to.have.been.called;
      });
      it('should not call other events', function() {
        var callback;
        callback = sinon.spy();
        this.dummy.on('foo', function() {});
        this.dummy.on('bar', callback);
        this.dummy.trigger('foo');
        return expect(callback).to.not.have.been.called;
      });
      return it('should allow for passing data', function() {
        var callback;
        callback = sinon.spy();
        this.dummy.on('foo', callback);
        this.dummy.trigger('foo', 'bar');
        return expect(callback.args[0][0]).to.eql('bar');
      });
    });
    return describe('#off', function() {
      it('should unbind an event', function() {
        var callback;
        callback = sinon.spy();
        this.dummy.on('foo', callback);
        this.dummy.off('foo');
        this.dummy.trigger('foo');
        return expect(callback).to.not.have.been.called;
      });
      return it('should unbind an event only for a certain callback', function() {
        var callback1, callback2;
        callback1 = sinon.spy();
        callback2 = sinon.spy();
        this.dummy.on('foo', callback1);
        this.dummy.on('foo', callback2);
        this.dummy.off('foo', callback1);
        this.dummy.trigger('foo');
        expect(callback1).to.not.have.been.called;
        return expect(callback2).to.have.been.called;
      });
    });
  });

  describe('Job', function() {
    beforeEach(function() {
      return this.job = new Orange.Job('someType', {
        foo: 'bar'
      });
    });
    it('should store the type', function() {
      return expect(this.job.getType()).to.eql('someType');
    });
    it('should store the data', function() {
      return expect(this.job.getData()).to.eql({
        foo: 'bar'
      });
    });
    return describe('#perform', function() {
      return it('should push the job into the queue', function() {
        sinon.spy(Orange.Queue, 'push');
        this.job.perform();
        expect(Orange.Queue.push).to.have.been.calledWith(this.job);
        return Orange.Queue.push.restore();
      });
    });
  });

  describe('Queue', function() {
    var DummyJob;
    DummyJob = {};
    beforeEach(function() {
      return Orange.Queue.reset();
    });
    describe('#reset', function() {
      return it('should remove all jobs', function() {
        Orange.Queue.push(DummyJob);
        Orange.Queue.push(DummyJob);
        expect(Orange.Queue.getLength()).to.eql(2);
        Orange.Queue.reset();
        return expect(Orange.Queue.getLength()).to.eql(0);
      });
    });
    describe('#push', function() {
      return it('should update the length', function() {
        expect(Orange.Queue.getLength()).to.eql(0);
        Orange.Queue.push(DummyJob);
        return expect(Orange.Queue.getLength()).to.eql(1);
      });
    });
    describe('#pop', function() {
      return it('should update the length', function() {
        Orange.Queue.push(DummyJob);
        return expect(Orange.Queue.shift()).to.eql(DummyJob);
      });
    });
    return describe('#isEmpty', function() {
      it('should return false if there is still jobs available', function() {
        Orange.Queue.push(DummyJob);
        return expect(Orange.Queue.isEmpty()).to.be["false"];
      });
      return it('should return true if there is no jobs available', function() {
        Orange.Queue.push(DummyJob);
        Orange.Queue.shift();
        return expect(Orange.Queue.isEmpty()).to.be["true"];
      });
    });
  });

  describe('Utils', function() {
    describe('.log', function() {
      beforeEach(function() {
        return sinon.spy(console, 'log');
      });
      afterEach(function() {
        return console.log.restore();
      });
      it('should call console.log', function() {
        Orange.Utils.log('foo');
        return expect(console.log).to.have.been.calledWith('foo');
      });
      return it('should pass multiple arguments', function() {
        Orange.Utils.log('foo', 'bar');
        return expect(console.log).to.have.been.calledWith('foo', 'bar');
      });
    });
    describe('.underscore', function() {
      it('should convert a camelcase string', function() {
        var str;
        str = Orange.Utils.underscore('fooBar');
        return expect(str).to.eql('foo_bar');
      });
      return it('should leave a underscored string as is', function() {
        var str;
        str = Orange.Utils.underscore('foo_bar');
        return expect(str).to.eql('foo_bar');
      });
    });
    return describe('.webWorkerPathFor', function() {
      beforeEach(function() {
        return sinon.stub(Orange.Config, 'get').withArgs('workersPath').returns('./foo');
      });
      afterEach(function() {
        return Orange.Config.get.restore();
      });
      return it('should generate a proper path', function() {
        var path;
        path = Orange.Utils.webWorkerPathFor('fooBar');
        return expect(path).to.eql('./foo/foo_bar.js');
      });
    });
  });

  describe('Worker', function() {});

  describe('Basic functionality', function() {
    before(function() {
      return Orange.config.set('workersPath', 'fixtures/workers');
    });
    return describe('events', function() {
      it('should trigger success with correct data', function(done) {
        var job;
        job = new Orange.Job('sum', {
          members: [1, 2, 3]
        });
        job.on('success', function(event) {
          expect(event.data).to.be(6);
          return done();
        });
        return job.perform();
      });
      it('should trigger error with error object', function(done) {
        var job;
        job = new Orange.Job('hal9000', {
          members: [1, 2, 3]
        });
        job.on('error', function(event) {
          expect(event.data.error.message).to.be("Worker couldn't complete job.");
          return done();
        });
        return job.perform();
      });
      return it('should trigger error with error object', function(done) {
        var job;
        job = new Orange.Job('hal9000', {
          members: [1, 2, 3]
        });
        job.on('error', function(event) {
          expect(event.data.error.message).to.be("Worker couldn't complete job.");
          return done();
        });
        return job.perform();
      });
    });
  });

}).call(this);

/*
//@ sourceMappingURL=all.js.map
*/