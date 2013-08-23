'use strict'

eventBroker = require './eventBroker'
uuid = require 'uuid'

initialise = ->
  eventHandlers =
    generate: (event) ->
      event.respond uuid.v4

  eventBroker.subscribe 'tokens', eventHandlers

module.exports = { initialise }

