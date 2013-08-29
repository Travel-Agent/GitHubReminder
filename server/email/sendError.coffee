'use strict'

initialise = (transport, config, subjectPrefix) ->
  (event) ->
    transport.sendEmail {
      from: config.from
      to: config.errors
      subject: "#{subjectPrefix}   E R R O R !"
      text: 'TODO'
    }, event.respond

module.exports = { initialise }

