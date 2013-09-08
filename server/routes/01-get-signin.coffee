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
      generateToken = ->
        console.log 'AFTER CLEAR:'
        console.dir request.state

        tokenHelper.generate receiveToken

      receiveToken = (token) ->
        console.log 'BEFORE SET:'
        console.dir request.state

        request.auth.session.set _.extend request.state, { token }
        setTimeout _.partial(respond, token), 0

      respond = (token) ->
        console.log 'AFTER SET:'
        console.dir request.state

        request.reply.view 'content/signin.html',
          url: "#{config.uri}?client_id=#{encodeURIComponent config.id}&scope=#{encodeURIComponent config.scope}&state=#{encodeURIComponent token}"

      if request.auth.isAuthenticated
        return request.reply.redirect '/'

      console.log 'BEFORE CLEAR:'
      console.dir request.state

      request.auth.session.clear()
      setTimeout generateToken, 0

