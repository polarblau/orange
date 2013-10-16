describe 'Config', ->

  DEFAULTS =
    maxWorkerPoolSize: 4
    maxRetries       : 3
    workersPath      : '/lib/workers/'

  beforeEach ->
    # Reset
    Orange.Config.set(DEFAULTS)

  describe '#get', ->
    describe 'when called without arguments', ->
      it 'should return an object', ->
        expect(Orange.Config.get()).to.be.a 'object'

      it 'should return the defaults', ->
        expect(Orange.Config.get()).to.eql DEFAULTS

    describe 'when called with key', ->
      it 'should return the settings value', ->
        expect(Orange.Config.get('maxRetries')).to.equal DEFAULTS.maxRetries

  describe '#set', ->
    describe 'when called with two arguments', ->
      it 'should set a key/value pair', ->
        Orange.Config.set('maxRetries', 10)
        expect(Orange.Config.get('maxRetries')).to.equal 10

      it 'should not set an non existant key', ->
        Orange.Config.set('foo', 'bar')
        expect(Orange.Config.get('foo')).to.not.exist

    describe 'when called with a hash (object)', ->
      it 'should set all pairs in the hash', ->
        Orange.Config.set
          maxWorkerPoolSize: 10
          maxRetries       : 12
        expect(Orange.Config.get('maxWorkerPoolSize')).to.be.equal 10
        expect(Orange.Config.get('maxRetries')).to.equal 12

      it 'should not set an non existant key', ->
        Orange.Config.set
          maxWorkerPoolSize: 10
          foo              : 'bar'
        expect(Orange.Config.get('maxWorkerPoolSize')).to.equal 10
        expect(Orange.Config.get('foo')).to.not.exist

  describe 'defaults', ->
    it 'should return defaults when nothing set', ->
      expect(Orange.Config.get()).to.eql DEFAULTS



class Dummy extends Orange.Eventable
  constructor: -> super()

describe 'Eventable', ->
  beforeEach ->
    @dummy = new Dummy

  describe '#on', ->
    it 'should bind an event with a callback', ->
      callback = sinon.spy()
      @dummy.on 'foo', callback
      @dummy.trigger 'foo'
      expect(callback).to.have.been.called

    it 'should bind multiple events', ->
      callback1 = sinon.spy()
      callback2 = sinon.spy()
      @dummy.on 'foo', callback1
      @dummy.on 'bar', callback2
      @dummy.trigger 'foo'
      @dummy.trigger 'bar'
      expect(callback1).to.have.been.called
      expect(callback2).to.have.been.called

    it 'should bind to the same event multiple times', ->
      callback1 = sinon.spy()
      callback2 = sinon.spy()
      @dummy.on 'foo', callback1
      @dummy.on 'foo', callback2
      @dummy.trigger 'foo'
      expect(callback1).to.have.been.called
      expect(callback2).to.have.been.called

    it 'should not call other events', ->
      callback = sinon.spy()
      @dummy.on 'foo', ->
      @dummy.on 'bar', callback
      @dummy.trigger 'foo'
      expect(callback).to.not.have.been.called

    it 'should allow for passing data', ->
      callback = sinon.spy()
      @dummy.on 'foo', callback
      @dummy.trigger 'foo', 'bar'
      expect(callback.args[0][0]).to.eql 'bar'

  describe '#off', ->
    it 'should unbind an event', ->
      callback = sinon.spy()
      @dummy.on 'foo', callback
      @dummy.off 'foo'
      @dummy.trigger 'foo'
      expect(callback).to.not.have.been.called

    it 'should unbind an event only for a certain callback', ->
      callback1 = sinon.spy()
      callback2 = sinon.spy()
      @dummy.on 'foo', callback1
      @dummy.on 'foo', callback2
      @dummy.off 'foo', callback1
      @dummy.trigger 'foo'
      expect(callback1).to.not.have.been.called
      expect(callback2).to.have.been.called



describe 'Job', ->

  beforeEach ->
    @job = new Orange.Job 'someType', {foo: 'bar'}

  it 'should store the type', ->
    expect(@job.getType()).to.eql 'someType'

  it 'should store the data', ->
    expect(@job.getData()).to.eql {foo: 'bar'}

  describe '#perform', ->
    it 'should push the job into the queue', ->
      sinon.spy(Orange.Queue, 'push')
      @job.perform()
      expect(Orange.Queue.push).to.have.been.calledWith @job
      Orange.Queue.push.restore()


describe 'Queue', ->

  DummyJob = {}

  beforeEach -> Orange.Queue.reset()

  describe '#reset', ->
    it 'should remove all jobs', ->
      Orange.Queue.push DummyJob
      Orange.Queue.push DummyJob
      expect(Orange.Queue.getLength()).to.eql 2
      Orange.Queue.reset()
      expect(Orange.Queue.getLength()).to.eql 0

  describe '#push', ->
    it 'should update the length', ->
      expect(Orange.Queue.getLength()).to.eql 0
      Orange.Queue.push DummyJob
      expect(Orange.Queue.getLength()).to.eql 1

  describe '#pop', ->
    it 'should update the length', ->
      Orange.Queue.push DummyJob
      expect(Orange.Queue.shift()).to.eql DummyJob

  describe '#isEmpty', ->
    it 'should return false if there is still jobs available', ->
      Orange.Queue.push DummyJob
      expect(Orange.Queue.isEmpty()).to.be.false

    it 'should return true if there is no jobs available', ->
      Orange.Queue.push DummyJob
      Orange.Queue.shift()
      expect(Orange.Queue.isEmpty()).to.be.true

describe 'Utils', ->

  describe '.log', ->

    beforeEach ->
      sinon.spy(console, 'log')

    afterEach ->
      console.log.restore()

    it 'should call console.log', ->
      Orange.Utils.log('foo')
      expect(console.log).to.have.been.calledWith 'foo'

    it 'should pass multiple arguments', ->
      Orange.Utils.log('foo', 'bar')
      expect(console.log).to.have.been.calledWith 'foo', 'bar'

  describe '.underscore', ->

    it 'should convert a camelcase string', ->
      str = Orange.Utils.underscore 'fooBar'
      expect(str).to.eql 'foo_bar'

    it 'should leave a underscored string as is', ->
      str = Orange.Utils.underscore 'foo_bar'
      expect(str).to.eql 'foo_bar'

  describe '.webWorkerPathFor', ->

    beforeEach ->
      sinon.stub(Orange.Config, 'get').withArgs('workersPath').returns('./foo')

    afterEach ->
      Orange.Config.get.restore()

    it 'should generate a proper path', ->
      path = Orange.Utils.webWorkerPathFor('fooBar')
      expect(path).to.eql './foo/foo_bar.js'


describe 'Worker', ->

describe 'Basic functionality', ->

  before ->
    Orange.config.set 'workersPath', 'fixtures/workers'

  describe 'events', ->
    it 'should trigger success with correct data', (done)->
      job = new Orange.Job 'sum', members: [1..3]
      job.on 'success', (event)->
        expect(event.data).to.be 6
        done()
      job.perform()

    it 'should trigger error with error object', (done)->
      job = new Orange.Job 'hal9000', members: [1..3]
      job.on 'error', (event)->
        expect(event.data.error.message).to.be "Worker couldn't complete job."
        done()
      job.perform()

    it 'should trigger error with error object', (done)->
      job = new Orange.Job 'hal9000', members: [1..3]
      job.on 'error', (event)->
        expect(event.data.error.message).to.be "Worker couldn't complete job."
        done()
      job.perform()
