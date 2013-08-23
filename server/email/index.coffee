'use strict'

nodemailer = require 'nodemailer'
eventBroker = require '../eventBroker'
config = require('../../config').email

initialise = ->
  parseEventHandlers = (fileName, handlers) ->
    handlers[fileName] = require("./#{fileName}").initialise transport, config, '[GitHubReminder]'
    handlers

  transport = nodemailer.createTransport 'SES',
    AWSAccessKeyID: config.key
    AWSSecretKey: config.secret

  eventBroker.subscribe 'email', getFileNames().filter(isEventHandler).reduce parseEventHandlers, {}

getFileNames = ->
  fs.readdirSync __dirname

isEventHandler = (fileName) ->
  if fs.statSync(path.resolve __dirname, fileName).isFile()
    components = fileName.split '.'
    return components.length is 2 and components[0] isnt 'index' and components[1] is 'coffee'

  false

module.exports = { initialise }

