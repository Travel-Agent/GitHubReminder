'use strict'

events = require '../events'
eventBroker = require '../eventBroker'

module.exports =
  path: '/verify-email'
  method: 'GET'
  config:
    handler: (request) ->
      getUser = ->
        eventBroker.publish events.database.fetch, { type: 'users', query: { name: request.query.user } }, receiveUser
    
      receiveUser = (error, user) ->
        if error
          # TODO: send error email?
          request.reply.view 'content/error.html',
            error: "server/routes/07: #{error}"

        # TODO: Test request.query.token
        request.reply.view 'content/verified.html',
          emailAddress: user.email
    auth:
        mode: 'try'

