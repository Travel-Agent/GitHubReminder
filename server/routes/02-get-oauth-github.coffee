'use strict'

config = require '../../config'

module.exports =
  path: config.oauth.github.route
  method: 'GET'
  config:
    handler: ->
      if this.query.state is config.oauth.github.state
        # TODO: Fetch user from database, or create new user with default settings
        this.auth.session.set
          github: this.query.code
        this.reply.redirect '/'
    auth:
      mode: 'try'

