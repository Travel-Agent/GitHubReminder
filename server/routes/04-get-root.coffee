'use strict'

pubsub = require 'pub-sub'
eventBroker = pubsub.getEventBroker 'ghr'

module.exports =
  path: '/'
  method: 'GET'
  config:
    handler: (request) ->
      console.dir request.state

      getRecentStars = ->
        eventBroker.publish pubsub.createEvent
          name: 'gh-get-starred-recent'
          data: request.state.auth
          callback: receiveRecentStars

      receiveRecentStars = (stars) ->
        # TODO: Get user from database
        user = JSON.parse request.state.user
        request.reply.view 'content/index.html',
          user: 'TODO: user name, avatar, repo info'
          repos: stars
          emails: user.email
          isDaily: user.frequency is 'daily'
          isWeekly: user.frequency is 'weekly'
          isMonthly: user.frequency is 'monthly'
          isSaved: user.isSaved

      getRecentStars()

    auth: true

