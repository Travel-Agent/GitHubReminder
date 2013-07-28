'use strict'

pubsub = require 'pub-sub'
events = require './events'

eventBroker = pubsub.getEventBroker 'ghr'

subscribe = (category, handlers) ->
  for own id, handler of handlers
    eventBroker.subscribe
      name: events[category][id]
      callback: handler

publish = (name, data, callback) ->
  eventBroker.publish pubsub.createEvent { name, data, callback }

module.exports = { subscribe, publish }

