'use strict'

mongo = require 'mongodb'
pubsub = require 'pub-sub'
config = require('../config').database

retryLimit = 5
collections = [ 'users' ]
indices =
  users:
    name: 1

initialise = ->
  log 'initialising'
  server = new mongo.Server config.development.host, config.development.port, auto_reconnect: true
  connect new mongo.Db config.development.name, server, w: 1

connect = (database) ->
  doAsync database, 'open', [], connected, true

connected = (connection) ->
  collecions = {}
  eventBroker = undefined

  getCollections = ->
    doAsync connection, 'collectionNames', [], receiveCollections, true

  receiveCollections = (collectionNames) ->
    for collection in collections
      ensureCollection collection, collectionNames
    bindEvents()

  ensureCollection = (name, names) ->
    if names.indexOf "#{connection.name}.#{name}" is -1
      return createCollection name

    getCollection name

  createCollection = (name) ->
    doCollectionAction 'createCollection', name

  doCollectionAction = (action, name) ->
    after = (collection) ->
      setCollection name, collection
    doAsync connection, action, [ name ], after, true

  getCollection = (name) ->
    doCollectionAction 'collection', name

  setCollection = (name, collection) ->
    collections[name] = collection
    ensureIndex name

  ensureIndex = (name) ->
    doAsync connection, 'ensureIndex', [ name, indices[name], { unique: true, w: 1 } ], null, true

  bindEvents = ->
    eventBroker = pubsub.getEventBroker 'ghr'

    eventBroker.subscribe
      name: 'db-fetch'
      callback: fetch
    eventBroker.subscribe
      name: 'db-store'
      callback: store

    connection.on 'close', ->
      log 'connection closed'
    connection.on 'open', ->
      log 'connection opened'

  fetch = (event) ->
    data = event.getData()
    doAsync collections[data.type], 'findOne', [ data.query ], event.respond, false

  store = (event) ->
    data = event.getData()
    doAsync collections[data.type], 'update', [ data.instance, { upsert: true, w: 1 } ], event.respond, false

  getCollections()

doAsync = (object, methodName, args, after, failOnError, retryCount = 0) ->
  log "calling `#{methodName}` with arguments `#{args}`"

  after = after || ->
  argsCloned = args.slice 0

  argsCloned.push (error, result) ->
    if error
      if retryCount < retryLimit
        log "`#{methodName}` returned error `#{error}`"
        return doAsync object, methodName, args, after, failOnError, retryCount + 1

      if failOnError
        log 'fatal error, exiting'
        process.exit 1

      after error, null

    log "`#{methodName}` returned ok"

    if failOnError
      return after result

    after null, result

  object[methodName].apply object, argsCloned

log = (message) ->
  console.log "server/database: #{message}"

module.exports = { initialise }

