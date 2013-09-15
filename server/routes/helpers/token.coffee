'use strict'

_ = require 'underscore'
events = require '../../events'
eventBroker = require '../../eventBroker'
errorHelper = require './error'

check = (request, tokenType, callback) ->
  getUser = ->
    eventBroker.publish events.database.fetch, { type: 'users', query: { name: request.query.user } }, receiveUser

  receiveUser = (error, user) ->
    errorHelper.failOrContinue request, error, 'fetch user', _.partial checkToken, user

  checkToken = (user) ->
    unless user[tokenType] is request.query.token
      return errorHelper.fail request, tokenType, 'Error: token mismatch'

    callback user

  getUser()

generate = (callback) ->
  eventBroker.publish events.tokens.generate, null, callback

module.exports = { check, generate }

