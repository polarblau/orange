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

