'use strict'

pubsub = require 'pub-sub'
check = require 'check-types'
config = require('../../config').oauth.development

eventBroker = pubsub.getEventBroker 'ghr'

module.exports =
  path: config.route
  method: 'GET'
  config:
    handler: (request) ->
      # TODO: Sane error handling
      oauthToken = undefined

      getToken = ->
        if request.query.state is config.state
          eventBroker.publish pubsub.createEvent
            name: 'gh-get-token'
            data: request.query.code
            callback: receiveToken

      receiveToken = (token) ->
        oauthToken = token
        eventBroker.publish pubsub.createEvent
          name: 'gh-get-user'
          data: token
          callback: receiveGhUser

      receiveGhUser = (user) ->
        log 'got gh user'
        eventBroker.publish pubsub.createEvent
          name: 'db-fetch'
          data:
            type: 'users'
            query:
              name: user.login
          callback: (error, dbUser) ->
            receiveDbUser error, dbUser, user.login

      receiveDbUser = (error, user, name) ->
        if check.isObject user
          return respond user

        if error
          log "error fetching user from database `#{error}`"
          # TODO: Fail

        user =
          name: name
          frequency: 'weekly'
          isSaved: false

        eventBroker.publish pubsub.createEvent
          name: 'db-store'
          data:
            type: 'users'
            instance: user
          callback: (error) ->
            if error
              log "error storing user in database `#{error}`"
              # TODO: Fail

            respond user

      respond = (user) ->
        request.auth.session.set
          user: user.name
          auth: oauthToken
        request.reply.redirect '/'

      getToken()

    auth:
      mode: 'try'

log = (message) ->
  console.log "server/routes/02: #{message}"

