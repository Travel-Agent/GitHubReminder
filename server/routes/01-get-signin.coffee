'use strict'

_ = require 'underscore'
tokenHelper = require './helpers/token'
config = require('../../config').oauth
log = require('../log').initialise 'routes/01'

module.exports =
  path: '/signin'
  method: 'GET'
  config:
    auth:
      mode: 'try'
    handler: (request) ->
      receiveToken = (token) ->
        log.info "storing session token #{token}"
        request.auth.session.set { token }
        request.reply.view 'content/signin.html',
          url: "#{config.uri}?client_id=#{encodeURIComponent config.id}&scope=#{encodeURIComponent config.scope}&state=#{encodeURIComponent token}"

      log.info 'state:'
      console.dir request.state

      if request.auth.isAuthenticated
        log.warning 'already authenticated, redirecting'
        return request.reply.redirect '/'

      tokenHelper.generate receiveToken

