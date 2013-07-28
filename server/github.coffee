'use strict'

https = require 'https'
check = require 'check-types'
eventBroker = require './eventBroker'

packageInfo = require '../package.json'
userAgent = "#{packageInfo.name}/#{packageInfo.version} (node.js/#{process.version})"

config = require('../config').oauth[process.env.NODE_ENV || 'development']

host = 'api.github.com'

initialise = ->
  eventBroker.subscribe 'github', eventHandlers

eventHandlers =
  getToken: (event) ->
    request 'access token', {
      host: 'github.com'
      path: '/login/oauth/access_token'
      method: 'POST'
      headers:
        'User-Agent': userAgent
        'Accept': 'application/json'
    }, "client_id=#{config.id}&client_secret=#{config.secret}&code=#{event.getData()}", event.respond

  getUser: (event) ->
    request 'user', {
      host: host
      path: "/user?access_token=#{event.getData()}"
      method: 'GET'
      headers:
        'User-Agent': userAgent
        'Accept': 'application/json'
    }, null, event.respond

  getEmail: (event) ->
    request 'email', {
      host: host
      path: "/user/emails?access_token=#{event.getData()}"
      method: 'GET'
      headers:
        'User-Agent': userAgent
        'Accept': 'application/vnd.github.v3+json'
    }, null, event.respond

  getStarredRecent: (event) ->
    getStarred event.getData(), 'created', 'desc', 5, false, event.respond

  getStarredAll: (event) ->
    getStarred event.getData(), 'created', 'asc', 100, true, event.respond

request = (what, options, data, callback) ->
  log "requesting #{what} from `#{options.path}`"
  req = https.request options, (response) ->
    log "got #{what} response"

    body = ''

    response.on 'readable', ->
      body += response.read()

    response.on 'end', ->
      originIndex = options.path.indexOf '?'
      origin = if originIndex is -1 then options.path else options.path.substring 0, originIndex
      callback
        status: response.statusCode
        origin: origin
        headers: response.headers
        body: JSON.parse body

  if data
    log "writing data `#{data}`"
    req.write data

  req.end()

log = (message) ->
  console.log "server/github: #{message}"

getStarred = (oauthToken, sort, direction, count, getAll, callback, results = [], path = '') ->
  request 'stars', {
    host: host
    path: path || "/user/starred?access_token=#{oauthToken}&sort=#{sort}&direction=#{direction}&per_page=#{count}"
    method: 'GET'
    headers:
      'User-Agent': userAgent
  }, null, (response) ->
    if response.status is 200
      response.body = results.concat response.body
      links = parsePaginationLinks response.headers.link
      if getAll and check.isUnemptyString links.next
        return getStarred '', '', '', '', true, callback, response.body, links.next.substr links.indexOf(host) + host.length

    callback response

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

