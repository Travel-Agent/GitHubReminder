'use strict'

pubsub = require 'pub-sub'
config = require('../../config').oauth.development

eventBroker = pubsub.getEventBroker 'ghr'

module.exports =
  path: config.route
  method: 'GET'
  config:
    handler: (request) ->
      getToken = ->
        if request.query.state is config.state
          eventBroker.publish pubsub.createEvent
            name: 'gh-get-token'
            data: request.query.code
            callback: receiveToken

      receiveToken = (token) ->
        request.state.auth = token
        eventBroker.publish pubsub.createEvent
          name: 'gh-get-email'
          data: token
          callback: receiveEmail

      receiveEmail = (emails) ->
        # TODO: Get GH user before db user
        eventBroker.publish pubsub.createEvent
          name: 'db-fetch-user'
          data:
            # TODO: Query on user name
            email: emails
          callback: (error, user) ->
            receiveUser error, user, emails

      receiveUser = (error, user, emails) ->
        if error
          # TODO: Store user name instead of email
          user =
            email: emails
            frequency: 'weekly'
            isSaved: false
          eventBroker.publish pubsub.createEvent
            name: 'db-store-user'
            data: user
            callback: ->
              respond user

        respond user

      respond = (user) ->
        # TODO: Delete user cookie
        request.state.user = JSON.stringify user
        request.auth.session.set user
        request.reply.redirect '/'

      getToken()

    auth:
      mode: 'try'

log = (message) ->
  console.log "server/routes/02: #{message}"

