'use strict'

_ = require 'underscore'
userHelper = require './helpers/user'
errorHelper = require './helpers/error'
tokenHelper = require './helpers/token'

module.exports =
  path: '/unsubscribe'
  method: 'GET'
  config:
    auth:
      mode: 'try'
    handler: (request) ->
      deleteUser = (user) ->
        userHelper.delete request.query.user, _.partial respond, true, user.email

      respond = (isUserDeleted, emailAddress, error) ->
        errorHelper.failOrContinue request, error, "#{if isUserDeleted then 'delete' else 'update'} user", ->
          if isUserDeleted
            request.auth.session.clear()
          request.reply.view 'content/unsubscribed.html', { emailAddress, isUserDeleted }

      updateUser = (user) ->
        userHelper.update request.query.user, {}, { job: null, isSaved: null }, _.partial respond, false, user.email

      query =
        name: request.query.user

      tokenHelper.check request, 'unsubscribe', (user) ->
        if request.query.clobber is 'yes'
          return deleteUser user

        updateUser user


