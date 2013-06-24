'use strict'

config = require '../../config'

module.exports =
  path: '/'
  method: 'POST'
  config:
    # TODO: Limit to same origin
    # TODO: Validate query parameters
    #   e.g
    #     validate:
    #       query:
    #         name: hapi.types.String().required()
    # TODO: Fetch starred repos - http://developer.github.com/v3/activity/starring
    # TODO: CRON
    handler: ->
    auth: true

