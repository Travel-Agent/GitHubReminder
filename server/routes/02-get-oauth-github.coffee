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
            callback: (response) ->
              failOrContinue response, (body) ->
                oauthToken = body.access_token
                getGhUser()

      failOrContinue = (response, next) ->
        if response and response.status is 200
          return next response.body

        fail()

      fail = ->
        # TODO: render error view

      getGhUser = ->
        eventBroker.publish pubsub.createEvent
          name: 'gh-get-user'
          data: oauthToken
          callback: (response) ->
            failOrContinue response, getDbUser

      getDbUser = (user) ->
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
          return fail()

        user =
          name: name
          frequency: 'weekly'
          isSaved: false

        eventBroker.publish pubsub.createEvent
          name: 'db-store'
          data:
            type: 'users'
            query:
              name: user.name
            instance: user
          callback: (error) ->
            if error
              log "error storing user in database `#{error}`"
              fail()

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

