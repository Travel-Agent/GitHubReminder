'use strict'

{ types } = require 'hapi'
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
      emailType = undefined

      verifyEmail = ->
        if request.payload.email is 'other'
          if request.payload.otherEmail is ''
            return request.reply.redirect '/?saved=no&reason=otherEmail'
          emailType = 'otherEmail'
          # TODO: Verify other email address
        else
          emailType = 'email'
        generateJob()

      generateJob = ->
        eventBroker.publish events.jobs.generate, request.payload.frequency, (error, job) ->
          if error
            return fail 'generate job', error
          updateUser job

      fail = (what, reason) ->
        request.reply.view 'content/error.html',
          error: "server/routes/05: Failed to #{what}, reason `#{reason}`"

      updateUser = (job) ->
        eventBroker.publish events.database.update, {
          type: 'users'
          query:
            name: request.state.sid.user
          instance:
            email: request.payload[emailType]
            frequency: request.payload.frequency
            job: job
            isSaved: true
        }, finish

      finish = (error) ->
        if error
          return fail 'update user', error

        if request.payload.immediate is 'true'
          eventBroker.publish events.jobs.force, request.state.sid.user, ->
            # TODO: Await successful email dispatch before responding?

        request.reply.redirect '/?saved=yes'

      verifyEmail()

