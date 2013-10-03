'use strict'

_ = require 'underscore'
check = require 'check-types'
events = require './events'
eventBroker = require './eventBroker'
log = require './log'

# TODO: Do something with proper dates, time zones and so on
hourly = 1000 * 60 * 60
daily = hourly * 24
weekly = daily * 7
monthly = (weekly * 52) / 12
frequencies = { daily, weekly, monthly }

jobFrequency = hourly / 30

retryInterval = 1000
retryLimit = 10

initialise = ->
  log = log.initialise 'jobs'
  log.info 'initialising'
  runDueJobs()
  clearExpiredVerifications()
  eventBroker.subscribe 'jobs', eventHandlers

runDueJobs = ->
  log.info 'getting due jobs'
  eventBroker.publish events.database.fetchAll, {
    type: 'users'
    query:
      job:
        $lte: Date.now()
      verify:
        $exists: false
  }, (error, cursor) ->
    if error
      return log.error "failed to get due jobs, reason `#{error}`"

    cursor.toArray (error, users) ->
      if error
        return log.error "failed to convert due jobs to array, reason `#{error}`"

      log.info "got #{users.length} due jobs"

      users.forEach (user, index) ->
        log.info "running due job ##{index}:"
        console.dir user

        runJob null, user, (error) ->
          if error
            log.error "failed due job ##{index}, reason `#{error}`"
            log.error 'failed job:'
            return console.dir user

          log.info "completed due job ##{index}"

  setTimeout runDueJobs, jobFrequency

runJob = (error, user, after) ->
  repos = undefined
  retryCount = 0
  query =
    name: user.name

  getStarredRepos = ->
    eventBroker.publish events.github.getStarredAll, user.auth, (response) ->
      if response.status is 401 or response.status is 403
        deleteUser()
      httpFailOrContinue 'starred repositories', response, after, receiveStarredRepos

  deleteUser = ->
    log.info 'deleting unauthenticated user:'
    console.dir user
    eventBroker.publish events.database.delete, {
      type: 'users'
      query
    }

  receiveStarredRepos = (ignore, result) ->
    repos = result

    if repos.length is 0
      generateJob()
      return after "no starred repositories for #{user.name}"

    unless user.unsubscribe
      return getToken()

    sendReminder()

  getToken = ->
    eventBroker.publish events.tokens.generate, null, updateUser

  updateUser = (token) ->
    user.unsubscribe = token
    eventBroker.publish events.database.update, {
      type: 'users'
      query
      set:
        unsubscribe: token
      unset: {}
    }, (error, result) ->
      failOrContinue error, result, after, sendReminder

  sendReminder = ->
    unsubscribe = "unsubscribe?user=#{user.name}&token=#{user.unsubscribe}"
    sent = false

    eventBroker.publish events.retrier.try,
      until: ->
        sent
      action: (done) ->
        eventBroker.publish events.email.sendReminder, {
          to: user.email
          user: user.name
          frequency: user.frequency
          repo: selectRandom repos
          paths: {
            settings: ''
            unsubscribe
            clobber: "#{unsubscribe}&clobber=yes"
          }
        }, (error) ->
          if error
            log.error "failed to send email (attempt ##{retryCount}), reason `#{error}`"
          else
            sent = true
            generateJob()
          done()
      fail: ->
        after error
      limit: 6 # Give it a minute or so before leaving it for the next job
      interval: -1000

  generateJob = ->
    eventBroker.publish events.jobs.generate, user.frequency, (error, job) ->
      failOrContinue error, job, after, updateJob

  updateJob = (job) ->
    eventBroker.publish events.database.update, {
      type: 'users'
      query
      set: { job }
      unset: {}
    }, after

  failOrContinue error, user, after, getStarredRepos

failOrContinue = (error, result, fail, after) ->
  if error
    return fail error

  after result

httpFailOrContinue = (what, response, fail, after) ->
  unless response.status is 200
    return fail "received #{response.status} response from #{what} request"

  after null, response.body

selectRandom = (from) ->
  unless check.isArray from
    return from

  random = Math.floor Math.random() * from.length
  log.info "generated random index #{random} from #{from.length} items"
  from[random]

clearExpiredVerifications = ->
  eventBroker.publish events.database.delete,
    type: 'users'
    query:
      verifyExpire:
        $lt: Date.now()
  setTimeout clearExpiredVerifications, hourly

eventHandlers =
  generate: (event) ->
    log.info "generating job for `#{event.getData()}`"
    frequency = frequencies[event.getData()]
    if check.isNumber(frequency) is false
      log.error "bad frequency `#{event.getData()}`"
      return event.respond 'Invalid frequency'
    log.info "returning job `#{Date.now() + frequency}`"
    event.respond null, Date.now() + frequency

  force: (event) ->
    log.info 'forcing immediate job'
    eventBroker.publish events.database.fetch, {
      type: 'users'
      query:
        name: event.getData()
    }, (error, user) ->
      runJob error, user, event.respond

module.exports = { initialise }

