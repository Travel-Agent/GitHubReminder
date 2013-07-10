'use strict'

mongo = require 'mongodb'
config = require('../config').database

initialise = ->
  log 'initialising'
  server = new mongo.Server config.development.host, config.development.port, auto_reconnect: true
  db = new mongo.Db config.development.name, server, strict: true
  db.open connect

connect = ->
  log "connecting to `#{config.development.name}` on `#{config.development.host}:#{config.development.port}`"

  db.open (error, connection) ->
    if error
      log 'failed to connect'
      return connect()

    log 'connected'

    users = undefined

    connection.on 'close', ->
      log 'connection closed'

    connection.on 'open', ->
      log 'connection opened'

    getCollections = ->
      doAsync 'collectionNames', [], (collectionNames) ->
        if collectionNames.indexOf "#{connection.name}.users" is -1
          createUsersCollection()
        else
          getUsersCollection()

    doAsync = (methodName, args, after) ->
      log "calling `#{methodName}`"

      argsAsync = args.splice 0

      argsAsync.push (error, result) ->
        if error
          log "`#{methodName}` returned error"
          return doAsync methodName, args
        log "`#{methodName}` returned ok"
        after result

      connection[methodName].apply connection, argsAsync

    createUsersCollection = ->
      doAsync 'createCollection', [ 'users' ], setUsersCollection

    getUsersCollection = ->
      doAsync 'collection', [ 'users' ], setUsersCollection

    setUsersCollection = (collection) ->
      users = collection

    getCollections()

log = (message) ->
  console.log "server/database: #{message}"

