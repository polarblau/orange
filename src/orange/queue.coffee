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
