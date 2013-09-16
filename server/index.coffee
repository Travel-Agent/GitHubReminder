'use strict'

coffee = require 'coffee-script'

log = require './log'
log = log.initialise 'server'

log.info 'loading server modules'
modules = [ 'database', 'retrier', 'templates', 'github', 'email', 'tokens', 'errors', 'jobs' ]
modules.forEach (m) ->
  require("./#{m}").initialise()

hapi = require 'hapi'
config = require '../config'
routes = require './routes'

host = process.env.HOST || 'localhost'
port = parseInt process.env.PORT || '8080'
location = config.baseUri || "http://#{host}:#{port}"

log.info "creating server for #{location}/ on #{host}:#{port}"
server = hapi.createServer host, port, {
  location
  views:
    path: 'views'
    engines:
      html: 'handlebars'
  auth:
    scheme: 'cookie'
    password: config.cookies.password
    isSecure: location.substr(0, 6) is 'https:'
    redirectTo: '/signin'
    appendNext: false
  cache: config.sessions
}

log.info 'initialising routes'
routes.initialise server

log.info 'starting server'

server.start()

