class MethodNotFoundError extends Error
  name: 'MethodNotFoundError'
  constructor: (method) ->
    @message = "Worker does't implement method ##{method}"

@perform = (handler)->

  wrappedPerform = (data)->
    response = handler(data)
    respond('success', response)

  self.onmessage = (e)->
    {type, data} = e.data

    if type is 'perform'
      wrappedPerform(data)
    else
      throw new MethodNotFoundError(type)

@trigger = (event, data)->
  respond(event, data)

@log = (message)->
  respond("log", message)

respond = (type, response)->
  self.postMessage type: type, response: response

