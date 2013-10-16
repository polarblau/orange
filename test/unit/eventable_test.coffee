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


