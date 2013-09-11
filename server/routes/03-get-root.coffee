'use strict'

check = require 'check-types'
events = require '../events'
eventBroker = require '../eventBroker'
userHelper = require './helpers/user'
tokenHelper = require './helpers/token'
errorHelper = require './helpers/error'
httpErrorHelper = require './helpers/httpError'
log = require('../log').initialise 'routes/03'

module.exports =
  path: '/'
  method: 'GET'
  config:
    auth: true
    handler: (request) ->
      currentUser = currentEmails = currentStars = undefined
      outstandingRequests = 3

      begin = ->
        unless stateIsSane()
          log.error 'insane state detected'
          return signout()

        getUser()
        getEmails()
        getRecentStars()

      stateIsSane = ->
        check.isObject(request.state.sid) and
          check.isUnemptyString(request.state.sid.user) and
          check.isUnemptyString(request.state.sid.auth)

      signout = ->
        log.info 'signing out'
        request.reply.redirect '/signout'

      getUser = ->
        userHelper.fetch request.state.sid.user, receiveUser

      receiveUser = (error, user) ->
        storeUser = ->
          currentUser = user
          after()

        updateUser = (unsubscribe) ->
          userHelper.update request.state.sid.user, { unsubscribe }, {}, (error) ->
            errorHelper.failOrContinue request, error, 'update user', ->
              user.unsubscribe = unsubscribe
              storeUser()

        errorHelper.failOrContinue request, error, 'fetch user', ->
          if user is null
            return handleDeletedUser()

          if user.unsubscribe
            return storeUser()

          tokenHelper.generate updateUser
        , onError

      handleDeletedUser = ->
        log.warning 'user deleted'
        onError()
        signout()

      onError = ->
        outstandingRequests = -1

      after = ->
        outstandingRequests -= 1
        if outstandingRequests is 0
          respond()

      getEmails = (user) ->
        eventBroker.publish events.github.getEmail, request.state.sid.auth, receiveEmails

      receiveEmails = (response) ->
        httpErrorHelper.failOrContinue request, response, ->
          currentEmails = response.body.filter((email) ->
            email.verified is true
          ).map (email) ->
            address: email.email
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
        currentEmails.forEach (email) ->
          email.isSelected = email.address is currentUser.email
        isAwaitingVerification = check.isUnemptyString currentUser.verify
        isOtherEmail = currentUser.isSaved and currentEmails.every (email) ->
          email.isSelected is false
        if isOtherEmail
          if isAwaitingVerification
            otherEmail = currentUser.verifyEmail
          else
            otherEmail = currentUser.email
        else
          otherEmail = ''
        request.reply.view 'content/index.html', {
          user: currentUser.name
          avatar: currentUser.avatar
          email: currentEmails
          isOtherEmail
          otherEmail
          repos: currentStars
          isDaily: currentUser.frequency is 'daily'
          isWeekly: currentUser.frequency is 'weekly'
          isMonthly: currentUser.frequency is 'monthly'
          isSaved: currentUser.isSaved
          isFailed: request.query.saved is 'no'
          reason: request.query.reason
          isAwaitingVerification
          verificationEmail: currentUser.verifyEmail
          isSubscribed: currentUser.isSaved and !isAwaitingVerification
          unsubscribeLink: "/unsubscribe?user=#{currentUser.name}&token=#{currentUser.unsubscribe}&clobber=yes"
        }

      log.info 'handling request'
      log.info 'query:'
      console.dir request.query
      log.info 'state:'
      console.dir request.state

      begin()

