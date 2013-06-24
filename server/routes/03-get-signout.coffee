'use strict'

module.exports =
  path: '/signout'
  method: 'GET'
  config:
    handler: ->
      this.auth.session.clear()
      this.reply.redirect '/'
    auth: true

