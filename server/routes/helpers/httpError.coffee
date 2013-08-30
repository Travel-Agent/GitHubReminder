'use strict'

errorHelper = require './error'

failOrContinue = (request, response, next, onError) ->
  unless response and response.status is 200 and typeof response.body.error is 'undefined'
    return errorHelper.fail request, response.origin, getMessage(response), onError

  next response.body

getMessage = (response) ->
  # TODO: think this through properly
  "Error: #{response.status} #{if response.body.error then response.body.error else response.body}"

module.exports = { failOrContinue }

