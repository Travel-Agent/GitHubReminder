'use strict'

{ types } = require 'hapi'
_ = require 'underscore'
events = require '../events'
eventBroker = require '../eventBroker'
errorHelper = require './helpers/error'

module.exports =
  path: '/settings'
  method: 'POST'
  config:
    auth: true
    payload:
      mode: 'parse'
    validate:
      payload:
        email: types.String().email().allow('other').required()
        otherEmail: types.String().email().emptyOk()
        frequency: types.String().valid('daily', 'weekly', 'monthly').required()
        immediate: types.Boolean()
    handler: (request) ->
      emailAddress = undefined
      token = undefined

      verifyEmail = ->
        if request.payload.email is 'other'
          if request.payload.otherEmail is ''
            return request.reply.redirect '/?saved=no&reason=a%20valid%20email%20address%20was%20not%20provided'
          emailAddress = request.payload.otherEmail
          eventBroker.publish events.tokens.generate, null, (t) ->
            token = t
            updateUser { verify: token, verifyExpire: Date.now() }, verifyOtherEmail
        else
          emailAddress = request.payload.email
          generateJob()

      verifyOtherEmail = ->
        eventBroker.publish events.email.sendVerification, { emailAddress, token }, (error) ->
          next = _.partial finish, false, "/?verification=yes&emailAddress=#{encodeURIComponent emailAddress}"
          errorHelper.failOrContinue request, error, 'send verification email', next

      finish = (allowImmediate, redirectPath) ->
        if allowImmediate and request.payload.immediate is 'true'
          eventBroker.publish events.jobs.force, request.state.sid.user
        request.reply.redirect redirectPath

      generateJob = ->
        eventBroker.publish events.jobs.generate, request.payload.frequency, (error, job) ->
          errorHelper.failOrContinue request, error, 'generate job', _.partial receiveJob, job

      receiveJob = (job) ->
        updateUser { job }, (error) ->
          errorHelper.failOrContinue request, error, 'update user', _.partial finish, true, '/'

      updateUser = (fields, after) ->
        eventBroker.publish events.database.update, {
          type: 'users'
          query:
            name: request.state.sid.user
          set: _.defaults fields,
            email: emailAddress
            frequency: request.payload.frequency
            isSaved: true
        }, after

      verifyEmail()

