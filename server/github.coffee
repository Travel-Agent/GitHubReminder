'use strict'

https = require 'https'

pubsub = require 'pubsub'
eventBroker = pubsub.getEventBroker 'ghr'

packageInfo = require '../package.json'
userAgent = "#{packageInfo.name}/#{packageInfo.version} (node.js/#{process.version})"

initialise = ->
  eventBroker.subscribe
    name: 'gh-get-email'
    callback: getEmail

getEmail = (event) ->
  log 'getting email'
  https.get
    host: 'api.github.com'
    path: "/user/emails?access_token=#{event.getData()}"
    headers:
      'User-Agent': userAgent
  , (response) ->
    if response.status === 200
      log 'got response'

      body = ''

      response.on 'data', (data) ->
        log "received #{typeof data} data `#{data}`"
        body += data

      response.on 'end'
        log "finished data"
        event.respond JSON.parse body

log = (message) ->
  console.log "server/github: #{message}"

