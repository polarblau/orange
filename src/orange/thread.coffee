# Handles messaging between native web worker and job
class Orange.Thread extends Orange.Eventable

  constructor: (@job)->
    type       = @job.getType()
    path       = Orange.Utils.webWorkerPathFor(type)

    # manual job termination
    @job.on 'terminate', @kill if @job.isKeepAlive()

    @webWorker = new Orange.Worker(path)
    @webWorker.onmessage = @onMessage
    @webWorker.onerror   = @onError
    super()

  perform: ->
    @webWorker.postMessage type: 'perform', data: @job.getData()
    if @job.isKeepAlive()
      ww = @webWorker
      @job.on 'send', (data)=>
        ww.postMessage {type, data} = data

  kill: =>
    @webWorker.terminate()
    @webWorker = null

  onMessage: (message)=>
    {type, response} = message.data

    @job.handleEvent(type, response)
    @trigger 'done' unless @job.isKeepAlive()

  onError: (error)=>
    @job.handleEvent('error', error)
    @trigger 'done'
    error.preventDefault()


  `/* test-only-> */`
  Orange.__testOnly__.Thread = Thread
  `/* <-test-only */`
