'use strict'

eventBroker = require './eventBroker'

initialise = ->
  eventHandlers =
    report: (request, action, message) ->
      # TODO: send error email

      console.log 'P H I L ! ! !'
      console.dir request.route

      request.reply.view 'content/error.html',
        origin: request.route.name
        action
        message

  eventBroker.subscribe 'errors', eventHandlers

module.exports = { initialise }

