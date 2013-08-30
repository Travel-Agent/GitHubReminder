'use strict'

_ = require 'underscore'
events = require '../events'
eventBroker = require '../eventBroker'
tokenHelper = require './helpers/token'

module.exports =
  path: '/unsubscribe'
  method: 'GET'
  config:
    auth:
      mode: 'try'
    handler: (request) ->
      deleteUser = (user) ->
        eventBroker.publish events.database.delete, { type: 'users', query }, _.partial respond, true, user.email

      respond = (isUserDeleted, emailAddress, error) ->
        if error
          return eventBroker.publish events.errors.report, {
            request
            action: "#{if isUserDeleted then 'delete' else 'update'} user"
            message: error
          }

        request.reply.view 'content/unsubscribed.html', { emailAddress, isUserDeleted }

      updateUser = (user) ->
        eventBroker.publish events.database.update, {
          type: 'users'
          query
          set: {}
          unset:
            job: null
            isSaved: null
        }, _.partial respond, false, user.email

      query =
        name: request.query.user

      tokenHelper.check request, 'unsubscribe', (user) ->
        if request.query.clobber is 'yes'
          return deleteUser user

        updateUser user


