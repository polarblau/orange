Orange.Utils =

  log: (args...)->
    console?.log?.apply(console, args)

  underscore: (string)->
    string.replace(/([A-Z])/g, ($1) -> "_" + $1.toLowerCase())

  webWorkerPathFor: (type)->
    path = Orange.Config.get('workersPath')
    [path, "#{@underscore(type)}.js"].join('/').replace(/\/{2,}/, '/')
