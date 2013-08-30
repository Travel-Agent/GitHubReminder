'use strict'

eventBroker = require './eventBroker'

initialise = ->
  eventHandlers =
    report: (event) ->

      { request, action, message } = event.getData()

      # TODO: send error email

      request.reply.view 'content/error.html', {
        action
        message
        route: "#{request.route.method.toUpperCase()} #{request.route.path}"
        host: request.info.host
        path: request.path
        method: request.method.toUpperCase()
        user: request.state?.user
        referrer: request.info.referrer
      }

  eventBroker.subscribe 'errors', eventHandlers

module.exports = { initialise }

