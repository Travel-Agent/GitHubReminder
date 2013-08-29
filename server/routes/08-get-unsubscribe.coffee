'use strict'

_ = require 'underscore'

module.exports =
  path: '/unsubscribe'
  method: 'GET'
  config:
    auth:
      mode: 'try'
    handler: (request) ->
      getUser = ->
        eventBroker.publish events.database.fetch, { type: 'users', query }, receiveUser

      receiveUser = (error, user) ->
        if error
          return fail 'fetch user', error

        # TODO: decodeURIComponent?
        unless user.unsubscribe is request.query.token
         return fail 'unsubscribe', 'token mismatch'

        if request.query.clobber is 'yes'
          return deleteUser user

        updateUser user

      fail = (what, reason) ->
        # TODO: send error email?
        request.reply.view 'content/error.html',
          error: "server/routes/08: failed to #{what}, reason `#{reason}`"

      deleteUser = (instance) ->
        eventBroker.publish events.database.delete, { type: 'users', query }, _.partial respond, true, user.email

      respond = (isUserDeleted, emailAddress, error) ->
        if error
          return fail "#{if isUserDeleted then 'delete' else 'update'} user", error

        request.reply.view 'content/unsubscribed.html', { emailAddress, isUserDeleted }

      updateUser = (instance) ->
        delete instance.job
        delete instance.isSaved
        eventBroker.publish events.database.update, { type: 'users', query, instance }, _.partial respond, false, user.email

      query =
        name: request.query.user

      getUser()

