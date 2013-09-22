'use strict'

trier = require 'trier'
eventBroker = require './eventBroker'
log = require './log'

interval = 1000
limit = 10

initialise = ->
  log = log.initialise 'retrier'
  log.info 'initialising'
  eventBroker.subscribe 'retrier', eventHandlers

eventHandlers =
  try: (event) ->
    trier.attempt event.getData()

module.exports = { initialise }

