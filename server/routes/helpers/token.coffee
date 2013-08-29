'use strict'

events = require '../../events'
eventBroker = require '../../eventBroker'

check = (request, tokenType, callback) ->
  getUser = ->
    eventBroker.publish events.database.fetch, { type: 'users', name: request.query.user }, receiveUser

  receiveUser = (error, user) ->
    if error
      return fail 'fetch user', error

    unless user[tokenType] is request.query.token
      return fail tokenType, 'Error: token mismatch'

    callback user

  fail = (action, message) ->
    eventBroker.publish events.errors.report, { request, action, message }

  getUser()

module.exports = { check }

