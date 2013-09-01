'use strict'

userHelper = require './helpers/user'
errorHelper = require './helpers/error'
tokenHelper = require './helpers/token'

module.exports =
  path: '/verify-email'
  method: 'GET'
  config:
    auth:
        mode: 'try'
    handler: (request) ->
      updateUser = (user) ->
        userHelper.update request.query.user, {}, { verify: null, verifyExpire: null }, _.partial respond, user.email

      respond = (emailAddress, error) ->
        errorHelper.failOrContinue request, error, 'update user', _.partial request.reply.view, 'content/verified.html', { emailAddress }

      tokenHelper.check request, 'verify', updateUser

