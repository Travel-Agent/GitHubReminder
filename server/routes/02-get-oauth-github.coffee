'use strict'

_ = require 'underscore'
pubsub = require 'pub-sub'
check = require 'check-types'
events = require '../events'
eventBroker = require '../eventBroker'
userHelper = require './helpers/user'
errorHelper = require './helpers/error'
httpErrorHelper = require './helpers/httpError'
config = require('../../config').oauth

module.exports =
  path: config.route
  method: 'GET'
  config:
    auth:
      mode: 'try'
    handler: (request) ->
      auth = undefined

      getToken = ->
        if request.query.state is config.state
          eventBroker.publish events.github.getToken, request.query.code, (response) ->
            httpErrorHelper.failOrContinue request, response, (body) ->
              auth = body.access_token
              getGhUser()

      getGhUser = ->
        eventBroker.publish events.github.getUser, auth, (response) ->
          httpErrorHelper.failOrContinue request, response, getDbUser

      getDbUser = (user) ->
        userHelper.fetch user.login, (error, dbUser) ->
          receiveDbUser error, dbUser, user.login, user.avatar_url

      receiveDbUser = (error, user, name, avatar) ->
        if check.isObject user
          return respond user

        errorHelper.failOrContinue request, error, 'fetch user', _.partial storeDbUser, { name, avatar, auth, frequency: 'weekly', isSaved: false }

      storeDbUser = (user) ->
        userHelper.store user, (error) ->
          errorHelper.failOrContinue request, error, 'store user', _.partial respond, user

      respond = (user) ->
        request.auth.session.set { user: user.name, auth }
        request.reply.redirect '/'

      if request.query.error
        return errorHelper.fail request, 'OAuth', "Error: #{request.query.error}"

      getToken()

