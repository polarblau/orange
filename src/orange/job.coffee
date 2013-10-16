class JobStateTransitionError extends Error
  name: 'JobStateTransitionError'
  constructor: ->
    @message = "Can't execute #perform multiple times on same job."

class Orange.Job extends Orange.Eventable

  constructor: (@_type, @_data)->
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

  lock: ->
    @_isLocked = true

  isLocked: ->
    @_isLocked

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
