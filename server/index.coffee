'use strict'

console.log "$PORT is `#{process.env.PORT}`"

coffee = require 'coffee-script'

modules = [ 'templates', 'database', 'github', 'jobs', 'email' ]
modules.forEach (m) ->
  require("./#{m}").initialise()

hapi = require 'hapi'
config = require '../config'
routes = require './routes'

port = parseInt process.env.PORT || '8080'

server = hapi.createServer process.env.HOST || 'localhost', port,
  views:
    path: 'views'
    engines:
      html: 'handlebars'
  auth:
    scheme: 'cookie'
    password: config.cookies.password
    isSecure: false # TODO: Investigate SSL, set to true
    redirectTo: '/signin'
    appendNext: false
  cache: config.sessions

routes.initialise server

console.log "server: awaiting connections on port #{port}"

server.start()

