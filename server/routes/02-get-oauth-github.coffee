'use strict'

pubsub = require 'pubsub'
config = require '../../config'

eventBroker = pubsub.getEventBroker 'ghr'

module.exports =
  path: config.oauth.github.route
  method: 'GET'
  config:
    handler: ->
      self = this

      getEmail = ->
        if self.query.state is config.oauth.github.state
          console.log self.query
          event = pubsub.createEvent
            name: 'gh-get-email'
            data: self.query.code
            callback: receiveEmail

      receiveEmail = (emails) ->
        event = pubsub.createEvent
          name: 'db-fetch-user'
          data:
            email: emails
          callback: (error, user) ->
            receiveUser error, user, emails

      receiveUser = (error, user, emails) ->
        if error
          return respond email: emails

        respond user

      respond = (user) ->
        self.auth.session.set
          github: self.query.code
          user: user
        self.reply.redirect '/'

      getEmail()

    auth:
      mode: 'try'

