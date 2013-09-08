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
        console.log '** 03'
        eventBroker.publish events.github.getToken, request.query.code, (response) ->
          console.log '** 04'
          httpErrorHelper.failOrContinue request, response, (body) ->
            console.log '** 05'
            auth = body.access_token
            getGhUser()

      getGhUser = ->
        console.log '** 06'
        eventBroker.publish events.github.getUser, auth, (response) ->
          console.log '** 07'
          httpErrorHelper.failOrContinue request, response, getDbUser

      getDbUser = (user) ->
        console.log '** 08'
        userHelper.fetch user.login, (error, dbUser) ->
          console.log '** 09'
          receiveDbUser error, dbUser, user.login, user.avatar_url

      receiveDbUser = (error, user, name, avatar) ->
        console.log '** 10'
        if check.isObject user
          console.log '** 11'
          return respond user

        console.log '** 12'
        errorHelper.failOrContinue request, error, 'fetch user', _.partial storeDbUser, { name, avatar, auth, frequency: 'weekly', isSaved: false }

      storeDbUser = (user) ->
        console.log '** 13'
        userHelper.store user, (error) ->
          console.log '** 14'
          errorHelper.failOrContinue request, error, 'store user', _.partial respond, user

      respond = (user) ->
        console.log '** 15'
        request.auth.session.set _.extend request.state, { user: user.name, auth }
        console.log '** 16'
        request.reply.redirect '/'

      console.log '** 01'
      if request.query.error
        return errorHelper.fail request, 'OAuth', "Error: #{request.query.error}"

      console.log '** 02'
      unless request.query.state is request.state.sid?.token
        return errorHelper.fail request, 'OAuth', 'Error: state mismatch'

      getToken()

