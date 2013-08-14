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
        # TODO: Generate state on the fly? Would need to store states in db
        url: "#{config.uri}?client_id=#{config.id}&scope=#{config.scope}&state=#{config.state}"

