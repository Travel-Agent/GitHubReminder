'use strict'

prefixes =
  github: 'gh'
  database: 'db'
  jobs: 'jb'
  email: 'em'
  tokens: 'tk'
  errors: 'er'
  retrier: 'rt'

events =
  github: [ 'get-token', 'get-user', 'get-email', 'get-starred-recent', 'get-starred-all' ]
  database: [ 'fetch', 'fetch-all', 'insert', 'update', 'delete' ]
  jobs: [ 'generate', 'force' ]
  email: [ 'send-reminder', 'send-error', 'send-verification', 'send-deletion' ]
  tokens: [ 'generate' ]
  errors: [ 'report' ]
  retrier: [ 'try' ]

getEventMap = ->
  result = {}

  for own category, names of events
    result[category] = {}
    names.forEach (name) ->
      result[category][getCamelCasedString name] = "#{prefixes[category]}-#{name}"

  result

getCamelCasedString = (string) ->
  parts = string.split '-'
  parts.map((part, index) ->
    if index is 0
      return part
    part.substr(0, 1).toUpperCase() + part.substr 1
  ).join('')

module.exports = getEventMap()

