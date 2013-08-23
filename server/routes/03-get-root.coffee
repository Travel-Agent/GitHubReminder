'use strict'

check = require 'check-types'
events = require '../events'
eventBroker = require '../eventBroker'

module.exports =
  path: '/'
  method: 'GET'
  config:
    auth: true
    handler: (request) ->
      currentUser = currentEmails = currentStars = undefined
      outstandingRequests = 3

      begin = ->
        getUser()
        getEmails()
        getRecentStars()

      getUser = ->
        eventBroker.publish events.database.fetch, { type: 'users', query: { name: request.state.sid.user } }, (error, user) ->
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
        eventBroker.publish events.github.getEmail, request.state.sid.auth, (response) ->
          unless response.status is 200
            return responseFail response
          currentEmails = response.body.filter((email) ->
            email.verified is true
          ).map (email) ->
            address: email.email
            isSelected: currentUser.email is email.email
          after()

      responseFail = (response) ->
        fail "Received #{response.status} response from `#{response.origin}`"

      getRecentStars = ->
        eventBroker.publish events.github.getStarredRecent, request.state.sid.auth, (response) ->
          unless response.status is 200
            return responseFail response
          currentStars = response.body
          after()

      respond = ->
        isOtherEmail = currentUser.isSaved and currentEmails.every (email) ->
          email.isSelected is false
        request.reply.view 'content/index.html',
          user: currentUser.name
          avatar: currentUser.avatar
          email: currentEmails
          isOtherEmail: isOtherEmail
          otherEmail: if isOtherEmail then currentUser.email else ''
          repos: currentStars
          isDaily: currentUser.frequency is 'daily'
          isWeekly: currentUser.frequency is 'weekly'
          isMonthly: currentUser.frequency is 'monthly'
          isSaved: currentUser.isSaved
          isFailed: request.query.saved is 'no'
          reason: request.query.reason
          isAwaitingVerification: request.query.verification is 'yes'
          verificationEmail: if request.query.verification is 'yes' then request.query.emailAddress else ''

      begin()

