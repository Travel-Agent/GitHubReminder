'use strict'

events = require '../events'
eventBroker = require '../eventBroker'
tokenHelper = require './helpers/token'

module.exports =
  path: '/verify-email'
  method: 'GET'
  config:
    auth:
        mode: 'try'
    handler: (request) ->
      updateUser = (user) ->
        eventBroker.publish events.database.update, {
          type: 'users'
          query:
            name: request.query.user
          set: {}
          unset:
            verify: null
            verifyExpire: null
        }, _.partial respond, user.email

      respond = (emailAddress, error) ->
        if error
          return eventBroker.publish events.errors.report, {
            request
            action: 'update user'
            message: error
          }

        request.reply.view 'content/verified.html', { emailAddress }

      tokenHelper.check request, 'verify', updateUser

