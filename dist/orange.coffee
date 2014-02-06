###
orange - v0.2.0 - 2014-02-07
http://github.com/polarblau/orange
Copyright (c) 2014 Florian Plank
Licensed MIT
#### https://gist.github.com/paulirish/1579671#comment-91515
do ->
  w = window
  for vendor in ['ms', 'moz', 'webkit', 'o']
    break if w.requestAnimationFrame
    w.requestAnimationFrame = w["#{vendor}RequestAnimationFrame"]
    w.cancelAnimationFrame = (w["#{vendor}CancelAnimationFrame"] or
                  w["#{vendor}CancelRequestAnimationFrame"])

  # deal with the case where rAF is built in but cAF is not.
  if w.requestAnimationFrame
    return if w.cancelAnimationFrame
    browserRaf = w.requestAnimationFrame
    canceled = {}
    w.requestAnimationFrame = (callback) ->
      id = browserRaf (time) ->
        if id of canceled then delete canceled[id]
        else callback time
    w.cancelAnimationFrame = (id) -> canceled[id] = true

  # handle legacy browsers which don’t implement rAF
  else
    targetTime = 0
    w.requestAnimationFrame = (callback) ->
      targetTime = Math.max targetTime + 16, currentTime = +new Date
      w.setTimeout (-> callback +new Date), targetTime - currentTime

    w.cancelAnimationFrame = (id) -> clearTimeout id
window.Orange = {}
`/* test-only-> */`
Orange.__testOnly__ = {}
`/* <-test-only */`
if 'Worker' of window
  Orange.Worker = Worker
else
  throw new Error('Your environment does not support WebWorkers')
Orange.Utils =

  log: (args...)->
    console?.log?.apply(console, args)

  underscore: (string)->
    string.replace(/([A-Z])/g, ($1) -> "_" + $1.toLowerCase())

  webWorkerPathFor: (type)->
    path = Orange.Config.get('workersPath')
    [path, "#{@underscore(type)}.js"].join('/').replace(/\/{2,}/, '/')

class Orange.Eventable

  constructor: ->
    @_subscriptions = {}

  # Subscribe to an event by passing name and callback function.
  #
  # Example:
  #   # subscribe to 'myevent'
  #   object.on 'myevent', (event)->
  #     console.log event.type, event.data # => 'myevent', []
  #   # subscribe to all events
  #   object.on '*', -> ...
  #
  on: (event, callback) =>
    @_subscriptions[event] = [] unless @_subscriptions[event]?
    @_subscriptions[event].push callback

  # Unsubscribe to an event by passing name optionally the
  # callback function.
  #
  # Example:
  #   # unsubscribe from 'myevent'
  #   object.off 'myevent'
  #
  off: (event, callback) =>
    if @_subscriptions[event]?
      if callback?
        @_subscriptions[event] = (cb for cb in @_subscriptions[event] when cb != callback)
      else
        subscriptions = []
        subscriptions[e] = cb for e, cb of @_subscriptions when e != event
        @_subscriptions = subscriptions

  # Trigger an event on all subscribers and allow for passing
  # data to the subscriber..
  #
  # Example:
  #   # trigger 'myevent' and pass data
  #   object.trigger 'myevent', 'a', 123
  #   # will pass the data within the event object as array:
  #   # {type: 'myevent', data: ['a', 123]}
  #
  trigger: (event, data)=>
    if @_subscriptions[event]?
      subcriptions = @_subscriptions[event]
      callback.call(@, data) for callback in subcriptions

do (Orange) ->

  DEFAULTS =
    maxWorkerPoolSize: 4
    maxRetries       : 3
    workersPath      : '/lib/workers/'

  # defining the settings object here within
  # the closure but outside the main object will prevent access
  settings = DEFAULTS

  # main configuration object with accessor methods
  Orange.Config =
    set: (key, value)->
      if value?
        settings[key] = value if settings[key]?
      else
        settings[k] = v for k, v of key when settings[k]?

    get: (key)->
      if key? then settings[key] else settings

do (Orange)->

  jobs   = []
  length = 0

  Orange.Queue =

    push: (job)->
      jobs.push job
      length = jobs.length

    getLength: ->
      length

    shift: ->
      job = jobs.shift()
      length = jobs.length
      job

    isEmpty: ->
      @getLength() <= 0

    reset: ->
      jobs = []
      length = jobs.length

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

  handleEvent: (type, response) ->
    @trigger type, response

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

  responders:
    error  : (error)   -> @job.handleError(error)
    success: (response)-> @job.handleSuccess(response)
    stream : (response)-> @job.handleStream(response)
    log    : (message) -> Orange.Utils.log(message)


  `/* test-only-> */`
  Orange.__testOnly__.Thread = Thread
  `/* <-test-only */`

# The Scheduler represents the completly autonomous
# heart of Orange. It pulls jobs of the queue, keeps
# track of workers and poolsize and caches workers for re-use
class SchedulerSingleton

  instance = null

  # keep track of jobs being executed in parallel
  poolSize = 0

  class Scheduler

    # TODO: take care of edgecases (FF!)
    tick: ->
      requestAnimationFrame(@update)

    update: =>
      unless Orange.Queue.isEmpty() or @poolIsFull()
        # get next job from queue
        job = Orange.Queue.shift()

        # create a worker
        thread = new Orange.Thread(job)
        thread.on 'done', ->
          removeThreadFromPool(thread)

        addThreadToPool(thread)

      @tick()

    poolIsFull: ->
      poolSize >= Orange.Config.get('maxWorkerPoolSize')

    # private

    addThreadToPool = (thread)->
      poolSize++
      thread.perform()

    removeThreadFromPool = (thread)->
      poolSize--
      thread.kill()
      thread = null


  @getInstance: ->
    instance ?= new Scheduler

# initialize
SchedulerSingleton.getInstance().tick()
