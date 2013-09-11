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
log = require('../log').initialise 'routes/02'

module.exports =
  path: config.route
  method: 'GET'
  config:
    auth:
      mode: 'try'
    handler: (request) ->
      auth = undefined

      getToken = ->
        log.info "exchanging auth code #{request.query.code} for access token"
        eventBroker.publish events.github.getToken, request.query.code, (response) ->
          httpErrorHelper.failOrContinue request, response, (body) ->
            auth = body.access_token
            log.info "received access token #{auth}"
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

      log.info 'handling request:'
      log.info 'query:'
      console.dir request.query
      log.info 'state:'
      console.dir request.state

      if request.query.error
        log.error request.query.error
        return errorHelper.fail request, 'OAuth', "Error: #{request.query.error}"

      unless request.query.state is request.state.sid?.token
        log.error "invalid state #{request.query.state}"
        return errorHelper.fail request, 'OAuth', 'Error: state mismatch'

      getToken()

