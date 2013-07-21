'use strict'

config = require('../../config').oauth.development

module.exports =
  path: '/signin'
  method: 'GET'
  config:
    handler: ->
      if this.auth.isAuthenticated
        return thisreply.redirect '/'

      this.reply.view 'content/signin.html',
        # TODO: Generate state on the fly? Would need to store states in db
        url: "#{config.uri}?client_id=#{config.id}&scope=#{config.scope}&state=#{config.state}"
    auth:
      mode: 'try'

