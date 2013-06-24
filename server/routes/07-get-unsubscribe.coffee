'use strict'

module.exports =
  path: '/unsubscribe'
  method: 'GET'
  config:
    # TODO: Get user id from this.query, remove cron job, update db
    handler: ->
    auth:
      mode: 'try'

