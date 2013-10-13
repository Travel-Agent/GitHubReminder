'use strict'

https = require 'https'
check = require 'check-types'
eventBroker = require './eventBroker'
log = require './log'

packageInfo = require '../package.json'
userAgent = "#{packageInfo.name}/#{packageInfo.version} (node.js/#{process.version})"

config = require('../config').oauth

host = 'api.github.com'

initialise = ->
  log = log.initialise 'github'
  log.info 'initialising'
  eventBroker.subscribe 'github', eventHandlers

eventHandlers =
  getToken: (event) ->
    request {
      host: 'github.com'
      path: '/login/oauth/access_token'
      method: 'POST'
      headers:
        'User-Agent': userAgent
        'Accept': 'application/json'
    }, "client_id=#{config.id}&client_secret=#{config.secret}&code=#{event.getData()}", event.respond

  getUser: (event) ->
    request {
      host: host
      path: "/user?access_token=#{event.getData()}"
      method: 'GET'
      headers:
        'User-Agent': userAgent
        'Accept': 'application/json'
    }, null, event.respond

  getEmail: (event) ->
    request {
      host: host
      path: "/user/emails?access_token=#{event.getData()}"
      method: 'GET'
      headers:
        'User-Agent': userAgent
        'Accept': 'application/vnd.github.v3+json'
    }, null, event.respond

  getStarredRecent: (event) ->
    getStarred event.getData(), 'created', 'desc', 3, false, event.respond

  getStarredAll: (event) ->
    getStarred event.getData(), 'created', 'asc', 100, true, event.respond

request = (options, data, callback) ->
  req = https.request options, (response) ->
    log[if response.statusCode >= 400 then 'error' else 'info'] "#{response.statusCode} result from `#{options.path}`"

    body = ''

    response.on 'readable', ->
      body += response.read()

    response.on 'end', ->
      body = JSON.parse body

      if response.statusCode >= 400
        log.error "{response.statusCode} response body from `#{options.path}`:"
        console.dir body

      callback {
        status: response.statusCode
        origin: "#{response.req.method} #{response.req.path}"
        headers: response.headers
        body
      }

  if data
    log.info "writing data `#{data}` to `#{options.path}`"
    req.write data

  req.end()

getStarred = (oauthToken, sort, direction, count, getAll, callback, results = [], path = '') ->
  request {
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
        return getStarred '', '', '', '', true, callback, response.body, links.next.substr links.next.indexOf(host) + host.length

    callback response

parsePaginationLinks = (links) ->
  if check.isUnemptyString links
    return links.split(',').map(parsePaginationLink).reduce combinePaginationLinks, {}

  []

parsePaginationLink = (link) ->
  parts = link.split ';'
  url = parts[0].trim()
  url = url.substring 1, url.length - 1
  key = parts[1].substring parts[1].indexOf('"') + 1, parts[1].lastIndexOf '"'
  { key, url }

combinePaginationLinks = (result, link) ->
  result[link.key] = link.url
  result

module.exports = { initialise }

