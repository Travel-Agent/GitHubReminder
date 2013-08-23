'use strict'

module.exports = { initialise }

initialise = (transport, config, subjectPrefix) ->
  (event) ->
    transport.sendEmail {
      from: config.from
      to: config.errors
      subject: "#{subjectPrefix}   E R R O R !"
      text: event.getData()
    }, event.respond

