'use strict'

fs = require 'fs'
path = require 'path'
nodemailer = require 'nodemailer'
eventBroker = require '../eventBroker'
config = require('../../config').email

initialise = ->
  parseEventHandler = (handlers, moduleName) ->
    handlers[moduleName] = require("./#{moduleName}").initialise transport, config, '[GitHubReminder]'
    handlers

  transport = nodemailer.createTransport 'SES',
    AWSAccessKeyID: config.key
    AWSSecretKey: config.secret

  eventBroker.subscribe 'email', getFileNames().filter(isEventHandler).map(removeExtension).reduce parseEventHandler, {}

getFileNames = ->
  fs.readdirSync __dirname

isEventHandler = (fileName) ->
  if fs.statSync(path.resolve __dirname, fileName).isFile()
    components = fileName.split '.'
    return components.length is 2 and components[0] isnt 'index' and components[1] is 'coffee'

  false

removeExtension = (fileName) ->
  fileName.split('.')[0]

module.exports = { initialise }

