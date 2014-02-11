class JobStateTransitionError extends Error
  name: 'JobStateTransitionError'
  constructor: ->
    @message = "Can't execute #perform multiple times on same job."

class Orange.Job extends Orange.Eventable

  constructor: (@_type, @_data, @_keepAlive = false)->
    @_retryCount = 0
    @_isLocked   = false
    @_response   = null
    @_lastError  = null
    super()

  perform: (isRetry = false)=>
    if @isLocked() and !isRetry
      throw new JobStateTransitionError
    else
      @lock()
      Orange.Queue.push(@)
    @ # don't want to return the queue

  terminate: =>
    @trigger 'terminate' if @isKeepAlive()

  handleError: (error)=>
    @_lastError = error
    if @_retryCount < Orange.Config.get 'maxRetries'
      @scheduleRetry()
      @trigger 'error', error
    else
      @trigger 'error', error
      @trigger 'failure', error
      @trigger 'complete'

  handleSuccess: (response)=>
    @_response = response
    @trigger 'complete'
    @trigger 'success', response

  handleEvent: (type, response) =>
    switch type
      when 'success' then @handleSuccess(response)
      when 'error'   then @handleError(response)
      when 'log'     then Orange.Utils.log(response)
      else @trigger type, response

  # TODO: use #trigger here as well, events should
  # always reflect across threads
  send: (type, data)->
    @trigger 'send', {type, data}

  lock: ->
    @_isLocked = true

  isLocked: ->
    @_isLocked

  isKeepAlive: ->
    @_keepAlive

  getType: ->
    @_type

  getData: ->
    @_data

  getResponse: ->
    @_response

  getLastError: ->
    @_lastError

  scheduleRetry: ->
    @_retryCount++
    # exponential backoff
    offset = Math.pow(@_retryCount, 2) * 1000
    setTimeout @perform, offset, true
