'use strict'

pubsub = require 'pub-sub'
check = require 'check-types'
events = require '../events'
eventBroker = require '../eventBroker'
config = require('../../config').oauth[process.env.NODE_ENV || 'development']

module.exports =
  path: config.route
  method: 'GET'
  config:
    auth:
      mode: 'try'
    handler: (request) ->
      oauthToken = undefined

      getToken = ->
        if request.query.state is config.state
          eventBroker.publish events.github.getToken, request.query.code, (response) ->
            failOrContinue response, (body) ->
              oauthToken = body.access_token
              getGhUser()

      failOrContinue = (response, next) ->
        if response and response.status is 200
          return next response.body

        fail "Received #{response.status} response from `#{response.origin}`"

      fail = (error) ->
        request.reply.view 'content/error.html',
          error: "server/routes/02: #{error}"

      getGhUser = ->
        eventBroker.publish events.github.getUser, oauthToken, (response) ->
          failOrContinue response, getDbUser

      getDbUser = (user) ->
        eventBroker.publish events.database.fetch, { type: 'users', query: { name: user.login } }, (error, dbUser) ->
          receiveDbUser error, dbUser, user.login, user.avatar_url

      receiveDbUser = (error, user, name, avatar) ->
        if check.isObject user
          return respond user

        if error
          return databaseFail 'fetch user', error

        storeDbUser
          name: name
          avatar: avatar
          auth: oauthToken
          frequency: 'weekly'
          isSaved: false

      databaseFail = (operation, error) ->
        fail "Failed to #{operation}, reason `#{error}`"

      storeDbUser = (user) ->
        eventBroker.publish events.database.insert, { type: 'users', instance: user }, (error) ->
          if error
            return databaseFail 'store user', error
          respond user

      respond = (user) ->
        request.auth.session.set
          user: user.name
          auth: oauthToken
        request.reply.redirect '/'

      getToken()

