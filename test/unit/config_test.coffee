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


