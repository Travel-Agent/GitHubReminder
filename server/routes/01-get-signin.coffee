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
      console.log '* 01'
      if request.auth.isAuthenticated
        console.log '* 02'
        return request.reply.redirect '/'

      console.log '* 03'
      tokenHelper.generate (token) ->
        console.log '* 04'
        #request.auth.session.set _.extend request.state, { token }

        console.log '* 05'
        request.reply.view 'content/signin.html',
          url: "#{config.uri}?client_id=#{encodeURIComponent config.id}&scope=#{encodeURIComponent config.scope}&state=#{encodeURIComponent token}"
        console.log '* 06'

