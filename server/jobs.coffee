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

baseUri = 'http://githubreminder.org/'

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
  }, (error, users) ->
    if error
      log.error "failed to get due jobs, reason `#{error}`"
    else
      log.info "got #{users.length} due jobs"
      users.forEach (user, index) ->
        log.info "running due job ##{index}:"
        console.dir user
        runJob null, user, (error) ->
          if error
            return log.error "failed due job ##{index}, reason `#{error}`"

          log.info "completed due job ##{index}"

    setTimeout runDueJobs, hourly

runJob = (error, user, after) ->
  repos = undefined

  getStarredRepos = ->
    eventBroker.publish events.github.getStarredAll, user.auth, (response) ->
      httpFailOrContinue 'starred repositories', response, after, receiveStarredRepos

  receiveStarredRepos = (ignore, result) ->
    repos = result

    unless user.unsubscribe
      return getToken()

    sendReminder()

  getToken = ->
    eventBroker.publish events.tokens.generate, null, updateUser

  updateUser = (token) ->
    eventBroker.publish events.database.update, {
      type: 'users'
      query:
        name: user.name
      set:
        unsubscribe: token
      unset: {}
    }, (error, result) ->
      failOrContinue error, result, after, sendReminder

  sendReminder = ->
    unsubscribe = "#{baseUri}unsubscribe?user=#{user.name}&token=#{user.unsubscribe}"
    eventBroker.publish events.email.sendReminder, {
      to: user.email
      frequency: user.frequency
      repo: selectRandom repos
      uris: {
        settings: baseUri
        unsubscribe
        clobber: "#{unsubscribe}&clobber=yes"
      }
    }, (error, response) ->
      failOrContinue error, response, after, generateJob

  generateJob = ->
    eventBroker.publish events.jobs.generate, user.frequency, (error, job) ->
      failOrContinue error, job, after, updateJob

  updateJob = (job) ->
    eventBroker.publish events.database.update, {
      type: 'users'
      query:
        name: user.name
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

