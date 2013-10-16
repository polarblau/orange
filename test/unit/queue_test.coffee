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
