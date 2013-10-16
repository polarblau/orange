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
