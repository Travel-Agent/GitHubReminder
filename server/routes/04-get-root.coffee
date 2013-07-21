'use strict'

pubsub = require 'pub-sub'
eventBroker = pubsub.getEventBroker 'ghr'

module.exports =
  path: '/'
  method: 'GET'
  config:
    handler: (request) ->
      console.dir request.state
      currentUser = currentEmails = currentStars = undefined
      outstandingRequests = 3

      # TODO: Sane error handling

      getUser = ->
        eventBroker.publish pubsub.createEvent
          name: 'db-fetch-user'
          data:
            name: request.state.user
          callback: (user) ->
            currentUser = user
            after()

      after = ->
        outstandingRequests -= 1
        if oustandingRequests is 0
          respond()

      getEmails = (user) ->
        eventBroker.publish pubsub.createEvent
          name: 'gh-get-email'
          data: request.state.auth
          callback: (emails) ->
            currentEmails = emails
            after()

      getRecentStars = ->
        eventBroker.publish pubsub.createEvent
          name: 'gh-get-starred-recent'
          data: request.state.auth
          callback: (stars) ->
            currentStars = stars
            after()

      respond = ->
        request.reply.view 'content/index.html',
          user: currentUser.name
          emails: currentEmails
          repos: currentStars
          isDaily: currentUser.frequency is 'daily'
          isWeekly: currentUser.frequency is 'weekly'
          isMonthly: currentUser.frequency is 'monthly'
          isSaved: currentUser.isSaved

      getRecentStars()

    auth: true

