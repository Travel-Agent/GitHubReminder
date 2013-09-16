'use strict'

_ = require 'underscore'
mongo = require 'mongodb'
events = require './events'
eventBroker = require './eventBroker'
log = require './log'
config = require('../config').database

collections = [ 'users' ]
indices =
  users: [ { spec: { name: 1 }, isUnique: 1 }, { spec: { job: 1 } }, { spec: { verifyExpire: 1 } } ]

initialise = ->
  log = log.initialise 'database'
  log.info 'initialising'
  server = new mongo.Server config.host, config.port, auto_reconnect: true
  connect new mongo.Db config.name, server, w: 1

connect = (database) ->
  doAsync database, 'open', [], connected, true

connected = (connection, authenticate = true) ->
  isConnected = true

  authenticationHandler = (result) ->
    if result is false
      log.error 'failed to authenticate database credentials'
      return process.exit 1
    connected connection, false

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
    ensureIndices name

  ensureIndices = (collectionName) ->
    indices[collectionName].forEach (index) ->
      ensureIndex index.spec, index.isUnique

  ensureIndex = (spec, isUnique) ->
    doAsync connection, 'ensureIndex', [ spec, { unique: isUnique, w: 1 } ], null, true

  bindEvents = ->
    eventBroker.subscribe 'database', eventHandlers

    connection.on 'close', ->
      isConnected = false
      log.warning 'connection closed'

    connection.on 'open', ->
      isConnected = true
      log.info 'connection opened'

  createEventHandler = (action, getArgs) ->
    (event) ->
      data = event.getData()

      log.info "event handler for #{action}:"
      console.dir data

      eventBroker.publish events.retrier.try, {
        name: "database #{action}"
        predicate: ->
          if isConnected is false
            log.error "no connection for #{action}"
          isConnected
        fail: ->
          event.respond 'no database connection'
      }, ->
        doAsync collections[data.type], action, getArgs(data), event.respond, false

  eventHandlers =
    fetch: createEventHandler 'findOne', (data) ->
      [ data.query ]

    fetchAll: createEventHandler 'find', (data) ->
      [ data.query ]

    insert: createEventHandler 'insert', (data) ->
      [ data.instance, { w: 1 } ]

    update: createEventHandler 'update', (data) ->
      [ data.query, { $set: data.set, $unset: data.unset }, { w: 1 } ]

    delete: createEventHandler 'remove', (data) ->
      [ data.query, { w: 1 } ]

  if authenticate is true and config.username and config.password
    return doAsync connection, 'authenticate', [ config.username, config.password ], authenticationHandler, true

  collecions = {}
  getCollections()

doAsync = (object, methodName, args, after, failOnError, retryCount = 0) ->
  log.info "calling `#{methodName}` with following arguments:"
  console.dir args

  after = after || ->
  argsCloned = args.slice 0

  argsCloned.push (error, result) ->
    # TODO: Use retrier
    if error
      log.error "`#{methodName}` returned error `#{error}`"

      if retryCount < 3
        return doAsync object, methodName, args, after, failOnError, retryCount + 1

      if failOnError
        log.error 'fatal, exiting'
        process.exit 1

      return after error, null

    log.info "`#{methodName}` returned ok"

    if failOnError
      return after result

    after null, result

  object[methodName].apply object, argsCloned

module.exports = { initialise }

