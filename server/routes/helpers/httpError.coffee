'use strict'

errorHelper = require './error'

failOrContinue = (request, response, next, onError) ->
  unless response and response.status is 200 and typeof response.body.error is 'undefined'
    return errorHelper.fail request, response.origin, getMessage(response), onError

  next response.body

getMessage = (response) ->
  # TODO: think this through properly
  if response.body.error
    message = response.body.error
  else if response.body.message
    message = response.body.message
  else
    message = response.body

  "Error: #{response.status} #{message}"

module.exports = { failOrContinue }

