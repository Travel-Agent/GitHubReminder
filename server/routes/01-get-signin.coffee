'use strict'

config = require '../../config'

module.exports =
  path: '/signin'
  method: 'GET'
  config:
    handler: ->
      if this.auth.isAuthenticated
        return thisreply.redirect '/'

      this.reply.view 'content/signin.html',
        # TODO: Generate state on the fly? Would need to store states in db
        url: "#{config.oauth.github.uri}?client_id=#{config.oauth.github.id}&scope=#{config.oauth.github.scope}&state=#{config.oauth.github.state}"
    auth:
      mode: 'try'

