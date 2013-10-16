class BatchStateTransitionError extends Error
  name: 'BatchStateTransitionError'
  constructor: ->
    @message = "Can't execute #perform multiple times on same batch."

class Orange.Batch extends Orange.Eventable

  constructor: (jobs = [])->
    @jobs                = []
    @_completedJobsCount = 0
    @_isLocked           = false

    @push(job) for job in jobs
    super()

  push: (job)->
    job.on 'complete', @_onJobCompleted
    @jobs.push job

  perform: ->
    if @isLocked()
      throw new BatchStateTransitionError
    else
      @lock()
      @_enableEventdispatch()
      job.perform() for job in @jobs

  lock: ->
    @_isLocked = true

  isLocked: ->
    @_isLocked

  _enableEventdispatch: =>
    for job in @jobs
      batch = @
      job.on 'complete',-> batch.trigger 'job:complete', @
      job.on 'success', -> batch.trigger 'job:success', @
      job.on 'error',   -> batch.trigger 'job:error', @
      job.on 'failure', -> batch.trigger 'job:failure', @

  _onJobCompleted: =>
    if ++@_completedJobsCount >= @jobs.length
      @trigger 'complete', @jobs