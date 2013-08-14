'use strict'

nodemailer = require 'nodemailer'
eventBroker = require './eventBroker'
config = require('../config').email

initialise = ->
  eventHandlers =
    sendReminder: (event) ->
      { to, data } = event.getData()
      transport.sendEmail {
        from: 'reminderbot@githubreminder.org'
        to: to
        subject: "[GitHubReminder] #{data.full_name}"
        text: 'TODO'
      }, event.respond
    sendError: (event) ->
      # nop
      event.respond()

  log 'initialising'

  transport = nodemailer.createTransport 'SES',
    AWSAccessKeyID: config.key
    AWSSecretKey: config.secret

  eventBroker.subscribe 'email', eventHandlers

log = (message) ->
  console.log "server/email: #{message}"

module.exports = { initialise }

