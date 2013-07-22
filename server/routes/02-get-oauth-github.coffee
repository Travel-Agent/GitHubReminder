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
        # TODO: Work out how to read state in 04
        #request.setState 'session', auth: token
        #oAuthToken = token
        request.session.set 'auth', { token }
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
          name: 'db-store-user'
          data: user
          callback: (error) ->
            if error
              log "error storing user in database `#{error}`"
              # TODO: Fail

            respond user

      respond = (user) ->
        # TODO: Work out how to read state in 04
        #request.setState 'session',
        #  user: user.name
        #  auth: oauthToken
        request.session.set 'user', name: user.name
        #request.session.set 'session',
        #  user: user.name
        #  auth: oauthToken
        request.auth.session.set user
        request.reply.redirect '/'

      getToken()

    auth:
      mode: 'try'

log = (message) ->
  console.log "server/routes/02: #{message}"

