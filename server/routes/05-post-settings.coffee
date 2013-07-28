'use strict'

{ types } = require 'hapi'
pubsub = require 'pub-sub'
eventBroker = pubsub.getEventBroker 'ghr'

module.exports =
  path: '/settings'
  method: 'POST'
  config:
    auth: true
    payload:
      mode: 'parse'
    validate:
      payload:
        email: types.String().email().allow 'other'
        otherEmail: types.String().email().emptyOk()
        frequency: types.String().valid 'daily', 'weekly', 'monthly'
    handler: (request) ->
      if request.payload.email is 'other'
        if request.payload.otherEmail is ''
          return request.reply.redirect '/?saved=no&reason=otherEmail'

        emailType = 'otherEmail'
      else
        emailType = 'email'

      eventBroker.publish pubsub.createEvent
        name: 'db-update'
        data:
          type: 'users'
          query:
            name: request.state.sid.user
          instance:
            email: request.payload[emailType]
            frequency: request.payload.frequency
            isSaved: true
        callback: (error) ->
          if error
            return request.reply.view 'content/error.html',
              error: "server/routes/05: Failed to update user, reason `#{error}`"

          request.reply.redirect '/?saved=yes'

