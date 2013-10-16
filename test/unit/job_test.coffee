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

