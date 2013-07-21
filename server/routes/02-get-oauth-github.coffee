'use strict'

pubsub = require 'pub-sub'
config = require('../../config').oauth.development

eventBroker = pubsub.getEventBroker 'ghr'

module.exports =
  path: config.route
  method: 'GET'
  config:
    handler: (request) ->
      # TODO: Sane error handling

      getToken = ->
        if request.query.state is config.state
          eventBroker.publish pubsub.createEvent
            name: 'gh-get-token'
            data: request.query.code
            callback: receiveToken

      receiveToken = (token) ->
        request.state.auth = token
        eventBroker.publish pubsub.createEvent
          name: 'gh-get-user'
          data: token
          callback: receiveGhUser

      receiveGhUser = (user) ->
        eventBroker.publish pubsub.createEvent
          name: 'db-fetch-user'
          data:
            name: user.login
          callback: (error, dbUser) ->
            receiveDbUser error, dbUser, user.login

      receiveDbUser = (error, user, name) ->
        # TODO: Sort out why error is not set if user doesn't exist
        if error
          user =
            name: name
            frequency: 'weekly'
            isSaved: false
          eventBroker.publish pubsub.createEvent
            name: 'db-store-user'
            data: user
            callback: ->
              respond user
        else
          respond user

      respond = (user) ->
        request.state.user = user.name
        request.auth.session.set user
        request.reply.redirect '/'

      getToken()

    auth:
      mode: 'try'

log = (message) ->
  console.log "server/routes/02: #{message}"

