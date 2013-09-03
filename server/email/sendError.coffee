'use strict'

log = require '../log'

initialise = (transport, config, subjectPrefix) ->
  log = log.initialise 'email/error'
  log.info 'initialising'

  (event) ->
    text = ''
    for own key, value of event.getData()
      text += "#{key}: #{value}\n"

    log.info "sending email to #{config.errors}:"
    console.log text

    transport.sendMail {
      from: config.from
      to: config.errors
      subject: "#{subjectPrefix} ERROR!"
      text
    }, event.respond

module.exports = { initialise }

