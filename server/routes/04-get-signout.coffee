'use strict'

module.exports =
  path: '/signout'
  method: 'GET'
  config:
    auth: true
    handler: ->
      this.auth.session.clear()
      this.reply.redirect '/'

