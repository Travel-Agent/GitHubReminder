'use strict'

https = require 'https'
check = require 'check-types'

pubsub = require 'pubsub'
eventBroker = pubsub.getEventBroker 'ghr'

packageInfo = require '../package.json'
userAgent = "#{packageInfo.name}/#{packageInfo.version} (node.js/#{process.version})"

host = 'api.github.com'
accept = 'application/vnd.github.v3+json

initialise = ->
  eventBroker.subscribe
    name: 'gh-get-email'
    callback: getEmail

  eventBroker.subscribe
    name: 'gh-get-starred-recent'
    callback: getRecentStarredRepositories

  eventBroker.subscribe
    name: 'gh-get-starred-all'
    callback: getAllStarredRepositories

getEmail = (event) ->
  log 'getting email'
  https.get
    host: host
    path: "/user/emails?access_token=#{event.getData()}"
    headers:
      'User-Agent': userAgent
      'Accept': 'application/vnd.github.v3+json'
  , (response) ->
    if response.status is 200
      log 'got response'

      body = ''

      response.on 'data', (data) ->
        log "received #{typeof data} data `#{data}`"
        body += data

      response.on 'end'
        log 'finished data'
        event.respond JSON.parse(body).filter((email) ->
          email.verified === true
        ).map (email) ->
          email.email

log = (message) ->
  console.log "server/github: #{message}"

getRecentStarredRepositories = (event) ->
  getStars event.getData(), 'created', 'desc', 5, false, event.respond

getAllStarredRepositories = (event) ->
  getStars event.getData(), 'created', 'asc', 100, true, event.respond

getStars = (oauthToken, sort, direction, count, getAll, callback, results = [], path = '') ->
  actualPath = path || "/user/starred?access_token=#{oauthToken}&sort=#{sort}&direction=#{direction}&per_page=#{count}"
  log "getting stars from `actualPath`"
  https.get
    host: host
    path: actualPath
    headers:
      'User-Agent': userAgent
  , (response) ->
    if response.status is 200
      log 'got starred repos'

      body = ''

      response.on 'data', (data) ->
        log "received #{typeof data} data `#{data}`"
        body += data

      response.on 'end'
        log 'finished data'
        results = results.concat JSON.parse body
        links = parsePaginationLinks response.headers.link
        if getAll and check.isUnemptyString links.next
          return getStars '', '', '', '', true, callback, results, links.next.substr links.indexOf(host) + host.length

        callback results

parsePaginationLinks = (links) ->
  if check.isUnemptyString links
    return links.split(',').map(parsePaginationLink).reduce combinePaginationLinks, {}

  []

parsePaginationLink = (link) ->
  parts = link.split ';'
  url = parts[0].trim()
  url = url.substring 1, url.length - 2
  key = parts[1].substring parts[1].indexOf('"') + 1, parts[1].lastIndexOf '"'
  { key, url }

combinePaginationLinks = (link, result) ->
  result[link.key] = link.url
  result

