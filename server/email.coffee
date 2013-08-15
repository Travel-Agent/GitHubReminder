'use strict'

nodemailer = require 'nodemailer'
eventBroker = require './eventBroker'
config = require('../config').email

subjectPrefix = '[GitHubReminder]'

initialise = ->
  eventHandlers =
    sendReminder: (event) ->
      { to, data } = event.getData()
      transport.sendEmail {
        from: config.from
        to: to
        subject: "#{subjectPrefix} #{data.full_name}"
        text: 'TODO'
      }, event.respond
    sendError: (event) ->
      transport.sendEmail {
        from: config.from
        to: config.errors
        subject: "#{subjectPrefix}   E R R O R !"
        text: event.getData()
      }, event.respond

  log 'initialising'

  transport = nodemailer.createTransport 'SES',
    AWSAccessKeyID: config.key
    AWSSecretKey: config.secret

  eventBroker.subscribe 'email', eventHandlers

log = (message) ->
  console.log "server/email: #{message}"

module.exports = { initialise }

