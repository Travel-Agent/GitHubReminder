'use strict'

{ types } = require 'hapi'
_ = require 'underscore'
events = require '../events'
eventBroker = require '../eventBroker'
userHelper = require './helpers/user'
errorHelper = require './helpers/error'
tokenHelper = require './helpers/token'

day = 24 * 60 * 60 * 1000

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
            return request.reply.redirect '/?saved=no&reason=a%20valid%20email%20address%20was%20not%20provided#settings'
          emailAddress = request.payload.otherEmail
          tokenHelper.generate (t) ->
            token = t
            updateUser { verify: token, verifyExpire: Date.now() + day, verifyEmail: emailAddress }, (error) ->
              errorHelper.failOrContinue request, error, 'update user', verifyOtherEmail
        else
          emailAddress = request.payload.email
          generateJob()

      verifyOtherEmail = ->
        eventBroker.publish events.email.sendVerification, {
          user: request.state.sid.user
          emailAddress
          token
        }, (error) ->
          next = _.partial finish, false
          errorHelper.failOrContinue request, error, 'send verification email', next

      finish = (allowImmediate) ->
        if allowImmediate and request.payload.immediate is 'true'
          eventBroker.publish events.jobs.force, request.state.sid.user
        request.reply.redirect '/#settings'

      generateJob = ->
        eventBroker.publish events.jobs.generate, request.payload.frequency, (error, job) ->
          errorHelper.failOrContinue request, error, 'generate job', _.partial receiveJob, job

      receiveJob = (job) ->
        updateUser { job }, (error) ->
          errorHelper.failOrContinue request, error, 'update user', _.partial finish, true

      updateUser = (fields, after) ->
        userHelper.update request.state.sid.user, _.defaults(fields,
          email: emailAddress
          frequency: request.payload.frequency
          isSaved: true
        ), {}, after

      verifyEmail()

