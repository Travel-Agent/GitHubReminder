'use strict'

check = require 'check-types'
events = require '../events'
eventBroker = require '../eventBroker'
errorHelper = require './helpers/error'
httpErrorHelper = require './helpers/httpError'

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
        eventBroker.publish events.database.fetch, { type: 'users', query: { name: request.state.sid.user } }, receiveUser

      receiveUser = (error, user) ->
        errorHelper.failOrContinue request, error, 'fetch user', ->
          currentUser = user
          after()
        , onError

      after = ->
        outstandingRequests -= 1
        if outstandingRequests is 0
          respond()

      onError = ->
        outstandingRequests = -1

      getEmails = (user) ->
        eventBroker.publish events.github.getEmail, request.state.sid.auth, receiveEmails

      receiveEmails = (response) ->
        httpErrorHelper.failOrContinue request, response, ->
          currentEmails = response.body.filter((email) ->
            email.verified is true
          ).map (email) ->
            address: email.email
            isSelected: currentUser.email is email.email
          after()
        , onError

      getRecentStars = ->
        eventBroker.publish events.github.getStarredRecent, request.state.sid.auth, receiveRecentStars

      receiveRecentStars = (response) ->
        httpErrorHelper.failOrContinue request, response, ->
          currentStars = response.body
          after()
        , onError

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

