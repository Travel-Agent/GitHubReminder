'use strict'

initialise = (transport, config, subjectPrefix) ->
  (event) ->
    text = ''
    for own key, value of event.getData()
      # TODO: Check
      text += "#{key}: #{value}\n"

    transport.sendMail {
      from: config.from
      to: config.errors
      subject: "#{subjectPrefix} ERROR!"
      text
    }, event.respond

module.exports = { initialise }

