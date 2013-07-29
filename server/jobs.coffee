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

log = (message) ->
  console.log "server/jobs: #{message}"

getDueJobs = ->
  eventBroker.publish events.database.fetchAll, { type: 'users', query: { job: { $lte: Date.now() } }, (error, jobs) ->
    if error
      # TODO: Email alert?
      console.log error
    else
      # TODO: Run jobs
      console.dir jobs

    setTimeout getDueJobs, hourly

eventHandlers =
  force: (event) ->
    # TODO: Get user, dispatch email, set job, update user, respond to event
    eventBroker.publish events.database.fetch, { type: 'users', query: { name: event.getData() } }, (error, user) ->

  generate: (event) ->
    frequency = frequencies[event.getData()]
    if check.isNumber(frequency) is false
      return event.respond 'Invalid frequency'
    event.respond null, Date.now() + frequency

module.exports = { intialise }

