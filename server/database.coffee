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
      log 'fetching collection names'

      connection.collectionNames (error, collectionNames) ->
        if error
          log 'failed to fetch collection names'
          return getCollections()

        log 'fetched collection names'

        if collectionNames.indexOf "#{connection.name}.users' is -1
          createUsersCollection()
        else
          getUsersCollection()

    createUsersCollection = ->
      log 'creating `users` collection'

      connection.createCollection 'users', (error, collection) ->
        if error
          log 'failed to create `users` collection'
          return createUsersCollection()

        log 'created `users` collection'

        users = collection

    getUsersCollection = ->
      connection.collection 'users', (error, collection) ->
        if error
          log 'failed to fetch `users` collection'
          return getUsersCollection()

        log 'fetched `users` collection'

        users = collection

    getCollections()
    # TODO: Fantasy-land promises for when either get or create users collection has passed?

log = (message) ->
  console.log "server/database: #{message}"

