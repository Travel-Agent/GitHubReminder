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
        log "getting user #{request.state.sid.user}"
        eventBroker.publish pubsub.createEvent
          name: 'db-fetch'
          data:
            type: 'users'
            query:
              name: request.state.sid.user
          callback: (error, user) ->
            if error
              log "error fetching user from database `#{error}`"
              return fail()

            log "got user #{user}"

            currentUser = user
            after()

      fail = ->
        log 'failing'
        outstandingRequests = -1
        # TODO: Render error view

      after = ->
        outstandingRequests -= 1
        log "#{outstandingRequests} outstanding requests"
        if outstandingRequests is 0
          respond()

      getEmails = (user) ->
        eventBroker.publish pubsub.createEvent
          name: 'gh-get-email'
          data: request.state.sid.auth
          callback: (response) ->
            log "email status is #{response.status}"
            unless response.status is 200
              return fail()

            currentEmails = response.body.filter((email) ->
              email.verified is true
            ).map (email) ->
              email.email

            after()

      getRecentStars = ->
        eventBroker.publish pubsub.createEvent
          name: 'gh-get-starred-recent'
          data: request.state.sid.auth
          callback: (response) ->
            log "stars status is #{response.status}"
            unless response.status is 200
              return fail()

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

log = (message) ->
  console.log "server/routes/04: #{message}"

