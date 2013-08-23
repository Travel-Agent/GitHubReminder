'use strict'

{ types } = require 'hapi'
_ = require 'underscore'
events = require '../events'
eventBroker = require '../eventBroker'
jobs = require '../jobs'

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
            updateUser { verify: token }, verifyOtherEmail
        else
          emailAddress = request.payload.email
          generateJob()

      verifyOtherEmail = ->
        eventBroker.publish events.email.sendVerification, {
          to: emailAddress
          data: token
        }, (error) ->
          failOrContinue error, 'send verification email', ->
            finish false, '/?verification=yes&emailAddress=#{encodeURIComponent emailAddress}'

      failOrContinue = (error, what, after) ->
        if error
          return fail what, error
        after()

      fail = (what, reason) ->
        # TODO: Send error email
        request.reply.view 'content/error.html',
          error: "server/routes/05: Failed to #{what}, reason `#{reason}`"

      finish = (allowImmediate, redirectPath) ->
        if allowImmediate and request.payload.immediate is 'true'
          eventBroker.publish events.jobs.force, request.state.sid.user
        request.reply.redirect redirectPath

      generateJob = ->
        eventBroker.publish events.jobs.generate, request.payload.frequency, (error, job) ->
          failOrContinue error, 'generate job', ->
            receiveJob user

      receiveJob = (job) ->
        updateUser { job }, (error) ->
          failOrContinue error, 'update user', ->
            finish true, '/'

      updateUser = (fields, after) ->
        eventBroker.publish events.database.update, {
          type: 'users'
          query:
            name: request.state.sid.user
          instance: _.defaults fields,
            email: emailAddress
            frequency: request.payload.frequency
            isSaved: true
        }, after

      verifyEmail()

