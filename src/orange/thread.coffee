class ResponderNotFoundError extends Error
  name: 'MethodNotFoundError'
  constructor: (type) ->
    @message = "Orange.Worker does't respond to method ##{type}"

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

  kill: =>
    @webWorker.terminate()
    @webWorker = null

  onMessage: (message)=>
    {type, response} = message.data

    if @responders[type]?
      @responders[type].call(@, response)
      @trigger 'done' unless @job.isKeepAlive()
    else
      @job.handleEvent(type, response)
      #throw new ResponderNotFoundError(type)

  onError: (error)=>
    @responders.error.call(@, error)
    @trigger 'done'
    error.preventDefault()

  # TODO: get rid of success/error and handle distinction in job?
  responders:
    error  : (error)   -> @job.handleError(error)
    success: (response)-> @job.handleSuccess(response)
    log    : (message) -> Orange.Utils.log(message)


  `/* test-only-> */`
  Orange.__testOnly__.Thread = Thread
  `/* <-test-only */`
