'use strict'

module.exports =
  path: '/signout'
  method: 'GET'
  config:
    auth: true
    handler: (request) ->
      request.auth.session.clear()
      request.reply.redirect '/'

