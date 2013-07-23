'use strict'

pubsub = require 'pub-sub'
eventBroker = pubsub.getEventBroker 'ghr'

module.exports =
  path: '/'
  method: 'GET'
  config:
    handler: (request) ->
      console.dir request.state
      console.dir request.auth
      currentUser = currentEmails = currentStars = undefined
      outstandingRequests = 3

      # TODO: Sane error handling

      getUser = ->
        # TODO: ARRRGH! FUCKING STATE!!
        eventBroker.publish pubsub.createEvent
          name: 'db-fetch'
          data:
            type: 'users'
            query:
              name: request.auth.session.user
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
          #data: request.state.session.auth
          data: request.session.get('auth').token
          callback: (emails) ->
            currentEmails = emails
            after()

      getRecentStars = ->
        # TODO: ARRRGH! FUCKING STATE!!
        eventBroker.publish pubsub.createEvent
          name: 'gh-get-starred-recent'
          data: request.auth.session.auth
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

