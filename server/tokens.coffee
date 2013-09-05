'use strict'

uuid = require 'uuid'
eventBroker = require './eventBroker'
log = require './log'

initialise = ->
  log = log.initialise 'tokens'
  log.info 'initialising'

  eventHandlers =
    generate: (event) ->
      uuid = uuid.v4()
      token = uuid.replace /-/g, ''
      log.info "returning token #{token} from uuid #{uuid}"
      event.respond token

  eventBroker.subscribe 'tokens', eventHandlers

module.exports = { initialise }

