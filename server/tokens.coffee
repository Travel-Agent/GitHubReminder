'use strict'

eventBroker = require './eventBroker'
uuid = require 'uuid'

initialise = ->
  eventHandlers =
    generate: (event) ->
      event.respond uuid.v4().replace /-/g, ''

  eventBroker.subscribe 'tokens', eventHandlers

module.exports = { initialise }

