'use strict'

events = require '../events'
eventBroker = require '../eventBroker'

module.exports =
  path: '/verify-email'
  method: 'GET'
  config:
    handler: (request) ->
      getUser = ->
        eventBroker.publish events.database.fetch, { type: 'users', query }, receiveUser

      receiveUser = (error, user) ->
        if error
          return fail 'fetch user', error

        unless user.email is request.query.address
          return fail 'verify email', 'email/token mismatch'

        updateUser user

      fail = (what, reason) ->
        # TODO: send error email?
        request.reply.view 'content/error.html',
          error: "server/routes/07: failed to #{what}, reason `#{reason}`"

      updateUser = (instance) ->
        delete instance.verify
        delete instance.verifyExpire
        eventBroker.publish events.database.update, { type: 'users', query, instance }, respond

      respond = (error) ->
        if error
          return fail 'update user', error

        request.reply.view 'content/verified.html',
          emailAddress: user.email

      query =
        verify: request.query.token

      getUser()

    auth:
        mode: 'try'

