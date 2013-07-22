'use strict'

mongo = require 'mongodb'
pubsub = require 'pub-sub'
config = require('../config').database

maxRetries = 10

initialise = ->
  log 'initialising'
  server = new mongo.Server config.development.host, config.development.port, auto_reconnect: true
  connect new mongo.Db config.development.name, server, w: 1

connect = (database) ->
  doAsync database, 'open', [], connected, true

connected = (connection) ->
  users = eventBroker = undefined

  getCollections = ->
    doAsync connection, 'collectionNames', [], receiveCollections, true

  receiveCollections = (collectionNames) ->
    if collectionNames.indexOf "#{connection.name}.users" is -1
      return createUsersCollection()

    getUsersCollection()

  createUsersCollection = ->
    doAsync connection, 'createCollection', [ 'users' ], setUsersCollection, true

  getUsersCollection = ->
    doAsync connection, 'collection', [ 'users' ], setUsersCollection, true

  setUsersCollection = (collection) ->
    users = collection
    createUsersIndex()

  createUsersIndex = ->
    doAsync connection, 'ensureIndex', [ 'users', { name: 1 }, { unique: true, w: 1 } ], bindEvents, true

  bindEvents = ->
    eventBroker = pubsub.getEventBroker 'ghr'

    eventBroker.subscribe
      name: 'db-fetch-user'
      callback: fetchUser
    eventBroker.subscribe
      name: 'db-store-user'
      callback: storeUser

    connection.on 'close', ->
      log 'connection closed'
    connection.on 'open', ->
      log 'connection opened'

  fetchUser = (event) ->
    doAsync users, 'findOne', [ event.getData() ], event.respond, false

  storeUser = (event) ->
    doAsync users, 'update', [ event.getData(), { upsert: true, w: 1 } ], event.respond, false

  getCollections()

log = (message) ->
  console.log "server/database: #{message}"

doAsync = (object, methodName, args, after, failOnError, retryCount = 0) ->
  log "calling `#{methodName}` with arguments `#{args}`"

  argsAsync = args.slice 0

  argsAsync.push (error, result) ->
    if error
      if retryCount < maxRetries
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

  object[methodName].apply object, argsAsync

module.exports = { initialise }

