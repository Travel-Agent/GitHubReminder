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
        request.auth.session.set { token }
        request.reply.view 'content/signin.html',
          url: "#{config.uri}?client_id=#{encodeURIComponent config.id}&scope=#{encodeURIComponent config.scope}&state=#{encodeURIComponent token}"

      if request.auth.isAuthenticated
        return request.reply.redirect '/'

      tokenHelper.generate receiveToken

