'use strict'

pubsub = require 'pub-sub'
eventBroker = pubsub.getEventBroker 'ghr'

module.exports =
  path: '/'
  method: 'GET'
  config:
    handler: (request) ->
      currentUser = currentEmails = currentStars = undefined
      outstandingRequests = 3

      begin = ->
        getUser()
        getEmails()
        getRecentStars()

      getUser = ->
        eventBroker.publish pubsub.createEvent
          name: 'db-fetch'
          data:
            type: 'users'
            query:
              name: request.state.sid.user
          callback: (error, user) ->
            if error
              return fail "Failed to fetch user from database, reason `#{error}`"

            currentUser = user
            after()

      fail = (error) ->
        outstandingRequests = -1
        request.reply.view 'content/error.html',
          error: "server/routes/04: #{error}"

      after = ->
        outstandingRequests -= 1
        if outstandingRequests is 0
          respond()

      getEmails = (user) ->
        eventBroker.publish pubsub.createEvent
          name: 'gh-get-email'
          data: request.state.sid.auth
          callback: (response) ->
            unless response.status is 200
              return responseFail response

            currentEmails = response.body.filter((email) ->
              email.verified is true
            ).map (email) ->
              email.email

            after()

      responseFail = (response) ->
        fail "Received #{response.status} response from `#{response.origin}`"

      getRecentStars = ->
        eventBroker.publish pubsub.createEvent
          name: 'gh-get-starred-recent'
          data: request.state.sid.auth
          callback: (response) ->
            unless response.status is 200
              return responseFail response

            currentStars = response.body
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

      begin()

    auth: true

