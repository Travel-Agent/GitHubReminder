'use strict'

_ = require 'underscore'
tokenHelper = require './helpers/token'
config = require('../../config').oauth

module.exports =
  path: '/signin'
  method: 'GET'
  config:
    auth:
      mode: 'try'
    handler: (request) ->
      receiveToken = (token) ->
        console.log '01 BEFORE SET:'
        console.dir request.state

        request.auth.session.set _.extend request.state, { token }
        setTimeout _.partial(respond, token), 0

      respond = (token) ->
        console.log '01 AFTER SET:'
        console.dir request.state

        request.reply.view 'content/signin.html',
          url: "#{config.uri}?client_id=#{encodeURIComponent config.id}&scope=#{encodeURIComponent config.scope}&state=#{encodeURIComponent token}"

      if request.auth.isAuthenticated
        return request.reply.redirect '/'

      tokenHelper.generate receiveToken

