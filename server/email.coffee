'use strict'

eventBroker = require './eventBroker'

initialise = ->
  log 'initialising'
  eventBroker.subscribe 'email', eventHandlers

log = (message) ->
  console.log "server/email: #{message}"

eventHandlers =
  sendReminder: (event) ->
    # nop
    event.respond()

  sendError: (event) ->
    # nop
    event.respond()

module.exports = { initialise }

