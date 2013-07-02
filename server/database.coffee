'use strict'

mongo = require 'mongodb'
config = require '../config'

initialise = ->
  server = new mongo.Server config.database.development.host, config.database.development.port, {}
  db = new mongo.Db config.database.development.name, server, {}

