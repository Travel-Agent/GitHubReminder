'use strict'

check = require 'check-types'
events = require './events'
eventBroker = require './eventBroker'

# TODO: Do something with proper dates, time zones and so on
hourly = 1000 * 60 * 60
daily = hourly * 24
weekly = daily * 7
monthly = (weekly * 52) / 12
frequencies = { daily, weekly, monthly }

initialise = ->
  log 'initialising'
  runDueJobs()
  eventBroker.subscribe 'jobs', eventHandlers

log = (message) ->
  console.log "server/jobs: #{message}"

runDueJobs = ->
  eventBroker.publish events.database.fetchAll, { type: 'users', query: { job: { $lte: Date.now() } } }, (error, users) ->
    if error
      log "failed to get due jobs, reason `#{error}`"
    else
      log "got #{users.length} due jobs"
      console.dir users
      users.forEach (user, index) ->
        log "running due job #{index}"
        runJob null, user, (error) ->
          if error
            return log "failed due job #{index}, reason `#{error}`"

          log "completed due job #{index}"

    setTimeout getDueJobs, hourly

runJob = (error, user, after) ->
  getStarredRepos = ->
    eventBroker.publish events.github.getStarredAll, user.auth, (response) ->
      httpFailOrContinue 'starred repositories', response, after, sendReminder

  sendReminder = (ignore, repos) ->
    eventBroker.publish events.email.sendReminder, { to: user.email, data: selectRandom repos }, (response) ->
      httpFailOrContinue 'reminder email', response, after, generateJob

  generateJob = ->
    eventBroker.publish events.jobs.generate, user.frequency, (error, job) ->
      failOrContinue error, job, after, updateJob

  updateJob = (job) ->
    eventBroker.publish events.database.update, { type: 'users', query: { name: user.name }, instance: { job } }, after

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
  # TODO: Consider discounting recent items? (should probably do that when fetching the repos)
  unless check.isArray from
    return from

  from[Math.floor Math.random() * from.length]

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
    eventBroker.publish events.database.fetch, { type: 'users', query: { name: event.getData() } }, (error, user) ->
      runJob error, user, event.respond

module.exports = { initialise }

