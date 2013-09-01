'use strict'

_ = require 'underscore'
check = require 'check-types'
events = require './events'
eventBroker = require './eventBroker'

# TODO: Do something with proper dates, time zones and so on
hourly = 1000 * 60 * 60
daily = hourly * 24
weekly = daily * 7
monthly = (weekly * 52) / 12
frequencies = { daily, weekly, monthly }

baseUri = 'http://githubreminder.org/'

initialise = ->
  log 'initialising'
  runDueJobs()
  clearExpiredVerifications()
  eventBroker.subscribe 'jobs', eventHandlers

log = (message) ->
  console.log "server/jobs: #{message}"

runDueJobs = ->
  log 'getting due jobs'
  eventBroker.publish events.database.fetchAll, {
    type: 'users'
    query:
      job:
        $lte: Date.now()
      verify:
        $exists: false
  }, (error, users) ->
    if error
      log "failed to get due jobs, reason `#{error}`"
    else
      log "got #{users.length} due jobs"
      users.forEach (user, index) ->
        log "running due job ##{index}"
        runJob null, user, (error) ->
          if error
            return log "failed due job ##{index}, reason `#{error}`"

          log "completed due job ##{index}"

    setTimeout runDueJobs, hourly

runJob = (error, user, after) ->
  repos = undefined

  getStarredRepos = ->
    eventBroker.publish events.github.getStarredAll, user.auth, (response) ->
      httpFailOrContinue 'starred repositories', response, after, receiveStarredRepos

  receiveStarredRepos = (ignore, result) ->
    repos = pruneRepos result

    unless user.unsubscribe
      return getToken()

    sendReminder()

  pruneRepos = (unpruned) ->
    pruned = unpruned.filter (repo) ->
      # TODO: Test, open to configuration
      repo.created < Date.now() - weekly

    if pruned.length is 0
      unpruned
    else
      pruned

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
    unsubscribe = "#{baseUri}/unsubscribe?user=#{user.name}&token=#{user.unsubscribe}"
    eventBroker.publish events.email.sendReminder, {
      to: user.email
      frequency: user.frequency
      repo: selectRandom repos
      uris: {
        settings: baseUri
        unsubscribe
        clobber: "#{unsubscribe}&clobber=yes"
      }
    }, (response) ->
      httpFailOrContinue 'reminder email', response, after, generateJob

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

selectRandomItem = (from) ->
  unless check.isArray from
    return from

  from[Math.floor Math.random() * from.length]

clearExpiredVerifications = ->
  eventBroker.publish events.database.delete,
    type: 'users'
    query:
      verifyExpire:
        $lt: Date.now()
  setTimeout clearExpiredVerifications, hourly

eventHandlers =
  generate: (event) ->
    log "generating job for `#{event.getData()}`"
    frequency = frequencies[event.getData()]
    if check.isNumber(frequency) is false
      log "bad frequency `#{event.getData()}`"
      return event.respond 'Invalid frequency'
    log "returning job `#{Date.now() + frequency}`"
    event.respond null, Date.now() + frequency

  force: (event) ->
    log 'forcing immediate job'
    eventBroker.publish events.database.fetch, {
      type: 'users'
      query:
        name: event.getData()
    }, (error, user) ->
      runJob error, user, event.respond

module.exports = { initialise }

