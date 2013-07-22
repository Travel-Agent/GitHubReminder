'use strict'

pubsub = require 'pub-sub'
eventBroker = pubsub.getEventBroker 'ghr'

module.exports =
  path: '/'
  method: 'GET'
  config:
    handler: (request) ->
      console.dir request
      currentUser = currentEmails = currentStars = undefined
      outstandingRequests = 3

      # TODO: Sane error handling

      getUser = ->
        # TODO: Work out how to read state
        eventBroker.publish pubsub.createEvent
          name: 'db-fetch-user'
          data:
            name: request.state.user
          callback: (error, user) ->
            if error
              log "error fetching user from database `#{error}`"
              # TODO: Fail

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
        # TODO: Work out how to read state
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

log = (message) ->
  console.log "server/routes/04: #{message}"

