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
