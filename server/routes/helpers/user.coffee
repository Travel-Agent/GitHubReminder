'use strict'

events = require '../../events'
eventBroker = require '../../eventBroker'

type = 'users'

fetch = (name, callback) ->
  eventBroker.publish events.database.fetch, { type, query: { name } }, callback

store = (instance, callback) ->
  eventBroker.publish events.database.insert, { type, instance }, callback

update = (name, set, unset, callback) ->
  eventBroker.publish events.database.update, { type, query: { name }, set, unset }, callback

deleteByName = (name, callback) ->
  eventBroker.publish events.database.delete, { type, query: { name } }, callback

module.exports = { fetch, store, update, delete: deleteByName }

