'use strict'

events = require './events'
eventBroker = require './eventBroker'

initialise = ->
  eventHandlers =
    report: (event) ->

      { request, action, message } = event.getData()
      data = {
        action
        message
        route: "#{request.route.method.toUpperCase()} #{request.route.path}"
        host: request.info.host
        path: request.path
        method: request.method.toUpperCase()
        user: request.state?.user
        referrer: request.info.referrer
      }

      eventBroker.publish events.email.sendError, data
      request.reply.view 'content/error.html', data

  eventBroker.subscribe 'errors', eventHandlers

module.exports = { initialise }

