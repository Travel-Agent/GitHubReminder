'use strict'

eventBroker = require './eventBroker'
log = require './log'

interval = 1000
limit = 10

initialise = ->
  log = log.initialise 'retrier'
  log.info 'initialising'
  eventBroker.subscribe 'retrier', eventHandlers

eventHandlers =
  try: (event) ->
    { name, predicate, fail } = event.getData()

    count = 0

    log.info "trying #{name}"

    test = ->
      unless predicate.apply null, arguments
        count += 1

        log.error "#{name} try ##{count} failed"

        if count < limit
          log.info "retrying #{name}"
          return setTimeout test, interval

        log.error "failing #{name}"
        return fail.apply null, arguments

      log.info "passing #{name}"
      event.respond.apply null, arguments

    test()

module.exports = { initialise }

