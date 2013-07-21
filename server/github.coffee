'use strict'

https = require 'https'
check = require 'check-types'

pubsub = require 'pub-sub'
eventBroker = pubsub.getEventBroker 'ghr'

packageInfo = require '../package.json'
userAgent = "#{packageInfo.name}/#{packageInfo.version} (node.js/#{process.version})"

config = require('../config').oauth.development

host = 'api.github.com'

initialise = ->
  eventBroker.subscribe
    name: 'gh-get-token'
    callback: getToken

  # TODO: Implement gh-get-user

  eventBroker.subscribe
    name: 'gh-get-email'
    callback: getEmail

  eventBroker.subscribe
    name: 'gh-get-starred-recent'
    callback: getRecentStarredRepositories

  eventBroker.subscribe
    name: 'gh-get-starred-all'
    callback: getAllStarredRepositories

getToken = (event) ->
  request 'access token', {
    host: 'github.com'
    path: '/login/oauth/access_token'
    method: 'POST'
    headers:
      'User-Agent': userAgent
      'Accept': 'application/json'
  }, "client_id=#{config.id}&client_secret=#{config.secret}&code=#{event.getData()}", (response) ->
    event.respond response.access_token

request = (what, options, data, callback) ->
  log "requesting #{what} from `#{options.path}`"
  req = https.request options, (response) ->
    if response.statusCode is 200
      log "got #{what} response"

      response.on 'readable', ->
        data = response.read()
        log "received #{typeof data} data `#{data}`"
        callback JSON.parse data

  if data
    log "writing data `#{data}`"
    req.write data

  req.end()

log = (message) ->
  console.log "server/github: #{message}"

getEmail = (event) ->
  request 'email', {
    host: host
    path: "/user/emails?access_token=#{event.getData()}"
    method: 'GET'
    headers:
      'User-Agent': userAgent
      'Accept': 'application/vnd.github.v3+json'
  }, null, (response) ->
    event.respond response.filter((email) ->
      email.verified is true
    ).map (email) ->
      email.email

getRecentStarredRepositories = (event) ->
  getStars event.getData(), 'created', 'desc', 5, false, event.respond

getAllStarredRepositories = (event) ->
  getStars event.getData(), 'created', 'asc', 100, true, event.respond

getStars = (oauthToken, sort, direction, count, getAll, callback, results = [], path = '') ->
  request path || "/user/starred?access_token=#{oauthToken}&sort=#{sort}&direction=#{direction}&per_page=#{count}", {
    host: host
    path: actualPath
    method: 'GET'
    headers:
      'User-Agent': userAgent
  }, null, (response) ->
    results = results.concat response
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

module.exports = { initialise }

