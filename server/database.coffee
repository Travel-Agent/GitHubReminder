'use strict'

mongo = require 'mongodb'
pubsub = require 'pub-sub'
config = require('../config').database

maxRetries = 10

initialise = ->
  log 'initialising'
  server = new mongo.Server config.development.host, config.development.port, auto_reconnect: true
  connect new mongo.Db config.development.name, server, strict: true

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
    bindEvents()

  bindEvents = ->
    eventBroker = pubsub.getEventBroker 'ghr'

    eventBroker.subscribe
      name: 'fetch-user'
      callback: read
    eventBroker.subscribe
      name: 'store-user'
      callback: write

    connection.on 'close', ->
      log 'connection closed'
    connection.on 'open', ->
      log 'connection opened'

  read = (event) ->
    # TODO: users.findOne
    # http://mongodb.github.io/node-mongodb-native/api-generated/collection.html#findone

  write = (event) ->
    # TODO: users.insert or users.update
    # http://mongodb.github.io/node-mongodb-native/api-generated/collection.html#insert
    # http://mongodb.github.io/node-mongodb-native/api-generated/collection.html#update

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

      process.exit 1

    log "`#{methodName}` returned ok"
    after result

  object[methodName].apply object, argsAsync

module.exports = { initialise }

