'use strict'

_ = require 'underscore'

initialise = (origin) ->
  result = {}
  for own methodName, method of methods
    # TODO: Check this
    result[methodName] = _.partial method, origin
  result

methods =
  info: createLogMethod 'INFO'
  warning: createLogMethod 'WARN'
  error: createLogMethod 'ERROR'

createLogMethod = (level) ->
  (origin, message) ->
    write level, origin, message

write = (level, origin, message) ->
  console.log "#{getTimestamp()} #{level} #{origin}: #{message}"

getTimestamp = ->
  time = new Date()
  # TODO: Check
  "#{time.getYear()}-#{time.getMonth() + 1}-#{time.getDate()} #{time.getHour()}:#{time.getMinutes()}:#{time.getSeconds()}.#{time.getMilliseconds}"

module.exports = { initialise }

