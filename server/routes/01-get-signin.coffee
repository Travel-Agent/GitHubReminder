'use strict'

config = require('../../config').oauth

module.exports =
  path: '/signin'
  method: 'GET'
  config:
    auth:
      mode: 'try'
    handler: (request) ->
      if request.auth.isAuthenticated
        return request.reply.redirect '/'

      request.reply.view 'content/signin.html',
        url: "#{config.uri}?client_id=#{encodeURIComponent config.id}&scope=#{encodeURIComponent config.scope}&state=#{encodeURIComponent request.state['connect.sid']}"

