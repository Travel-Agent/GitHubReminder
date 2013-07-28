'use strict'

{ types } = require 'hapi'
events = require '../events'
eventBroker = require '../eventBroker'

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
      # TODO: Verify other email address
      if request.payload.email is 'other'
        if request.payload.otherEmail is ''
          return request.reply.redirect '/?saved=no&reason=otherEmail'

        emailType = 'otherEmail'
      else
        emailType = 'email'

      eventBroker.publish events.database.update, {
        type: 'users'
        query:
          name: request.state.sid.user
        instance:
          email: request.payload[emailType]
          frequency: request.payload.frequency
          isSaved: true
      }, (error) ->
        if error
          return request.reply.view 'content/error.html',
            error: "server/routes/05: Failed to update user, reason `#{error}`"
        request.reply.redirect '/?saved=yes'

