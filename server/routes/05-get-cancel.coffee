'use strict'

userHelper = require './helpers/user'
errorHelper = require './helpers/error'

module.exports =
  path: '/cancel'
  method: 'GET'
  config:
    auth: true
    handler: (request) ->
      userHelper.fetch request.state.sid.user, (error, user) ->
        errorHelper.failOrContinue request, error, 'fetch user', ->
          request.reply.redirect "/unsubscribe?user=#{user.name}&token=#{user.unsubscribe}"

