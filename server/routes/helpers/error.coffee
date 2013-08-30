'use strict'

check = require 'check-types'
events = require '../../events'
eventBroker = require '../../eventBroker'

failOrContinue = (request, error, action, next, onError) ->
  if error
    return fail request, action, error, onError

  next()

fail = (request, action, message, onError) ->
  if check.isFunction onError
    onError()

  eventBroker.publish events.errors.report, { request, action, message }

module.exports = { failOrContinue, fail }

