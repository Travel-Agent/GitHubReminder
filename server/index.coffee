'use strict'

coffee = require 'coffee-script'

log = require './log'
log = log.initialise 'server'

log.info 'loading server modules'
modules = [ 'templates', 'database', 'github', 'jobs', 'email', 'tokens', 'errors' ]
modules.forEach (m) ->
  require("./#{m}").initialise()

hapi = require 'hapi'
config = require '../config'
routes = require './routes'

host = process.env.HOST || 'localhost'
port = parseInt process.env.PORT || '8080'

log.info "creating server on #{host}:#{port}"
server = hapi.createServer host, port,
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

log.info 'initialising routes'
routes.initialise server

log.info 'starting server'

server.start()

