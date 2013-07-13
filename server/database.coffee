'use strict'

mongo = require 'mongodb'
config = require('../config').database

initialise = ->
  log 'initialising'
  server = new mongo.Server config.development.host, config.development.port, auto_reconnect: true
  connect new mongo.Db config.development.name, server, strict: true

connect = (database) ->
  doAsync database, 'open', [], connected

connected = (connection) ->
  users = undefined

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

  connection.on 'close', ->
    log 'connection closed'
  connection.on 'open', ->
    log 'connection opened'

  getCollections()

log = (message) ->
  console.log "server/database: #{message}"

doAsync = (object, methodName, args, after) ->
  log "calling `#{methodName}`"

  argsAsync = args.slice 0

  argsAsync.push (error, result) ->
    if error
      log "`#{methodName}` returned error `#{error}`"
      return doAsync object, methodName, args, after
    log "`#{methodName}` returned ok"
    after result

  object[methodName].apply object, argsAsync

module.exports = { initialise }

