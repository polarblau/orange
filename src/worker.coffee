class Job

  respond = (type, response)->
    self.postMessage type: type, response: response

  constructor: (@context)->
    @_subscriptions = {}
    @_done          = false

  on: (event, callback) ->
    @_subscriptions[event] = [] unless @_subscriptions[event]?
    @_subscriptions[event].push callback

  done: (data) ->
    respond('success', data)
    @_done = true

  isDone: ->
    @_done

  error: (error) ->
    respond('error', error)

  trigger: (event, data)->
    # TODO: for completeness' sake also trigger local events
    # subcriptions = @_subscriptions[event]
    # callback(data) for callback in subcriptions
    # then report back to the main thread
    respond(event, data)

  log: (message)->
    respond("log", message)

# Pulic API
@perform = (handler)->

  job = new Job

  self.onmessage = (e)->
    {type, data} = e.data

    if type is 'perform'
      if (result = handler(job, data)) and not job.isDone()
        job.done(result)

    else if job._subscriptions[type]?
      subcriptions = job._subscriptions[type]
      callback(data) for callback in subcriptions

