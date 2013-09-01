'use strict'

_ = require 'underscore'

initialise = (origin) ->
  result = {}
  for own methodName, method of methods
    # TODO: Check this
    result[methodName] = _.partial method, origin
  result

createLogMethod = (level) ->
  (origin, message) ->
    write level, origin, message

write = (level, origin, message) ->
  console.log "#{getTimestamp()} #{level} #{origin}: #{message}"

getTimestamp = ->
  time = new Date()
  "#{formatDate time} #{formatTime time}"

formatDate = (time) ->
  "#{1900 + time.getYear()}-#{padTwoDigits time.getMonth() + 1}-#{padTwoDigits time.getDate()}"

formatTime = (time) ->
  "#{padTwoDigits time.getHours()}:#{padTwoDigits time.getMinutes()}:#{padTwoDigits time.getSeconds()}.#{padThreeDigits time.getMilliseconds()}"

padTwoDigits = (number) ->
  if number < 10
    return '0' + number

  number

padThreeDigits = (number) ->
  if number < 10
    return '00' + number

  if number < 100
    return '0' + number

  number

methods =
  info: createLogMethod 'INFO'
  warning: createLogMethod 'WARN'
  error: createLogMethod 'ERROR'

module.exports = { initialise }

