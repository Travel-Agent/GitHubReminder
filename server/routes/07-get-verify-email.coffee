'use strict'

events = require '../events'
eventBroker = require '../eventBroker'

module.exports =
  path: '/verify-email'
  method: 'GET'
  config:
    handler: (request) ->
      getUser = ->
        eventBroker.publish events.database.fetch, { type: 'users', query: { name: user.login } }, receiveUser
    
      receiveUser = (error, user) ->
        if error
    auth:
        mode: 'try'

