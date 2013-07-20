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
  doAsync database, 'open', [], connected

connected = (connection) ->
  users = eventBroker = undefined

  getCollections = ->
    doAsync connection, 'collectionNames', [], (collectionNames) ->
      if collectionNames.indexOf "#{connection.name}.users" is -1
        createUsersCollection()
      else
        getUsersCollection()

  createUsersCollection = ->
    doAsync connection, 'createCollection', [ 'users' ], setUsersCollection

  getUsersCollection = ->
    doAsync connection, 'collection', [ 'users' ], setUsersCollection

  setUsersCollection = (collection) ->
    users = collection
    createUsersIndex()

  createUsersIndex = ->
    doAsync connection, 'ensureIndex', [ 'users', { email: 1 }, { unique: true, w: 1 } ], bindEvents

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
    users.findOne event.getData(), event.respond

  storeUser = (event) ->
    doAsync users, 'update', [ event.getData(), { upsert: true, w: 1 } ], event.respond

  getCollections()

log = (message) ->
  console.log "server/database: #{message}"

doAsync = (object, methodName, args, after, retryCount = 0) ->
  log "calling `#{methodName}`"

  argsAsync = args.slice 0

  argsAsync.push (error, result) ->
    if error
      if retryCount < maxRetries
        log "`#{methodName}` returned error `#{error}`"
        return doAsync object, methodName, args, after, retryCount + 1

      # TODO: Replace with email alert before production deployment
      process.exit 1

    log "`#{methodName}` returned ok"
    after result

  object[methodName].apply object, argsAsync

module.exports = { initialise }

