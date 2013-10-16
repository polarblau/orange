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
