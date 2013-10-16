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
