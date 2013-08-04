'use strict'

coffee = require 'coffee-script-redux'
coffee.register()

modules = [ 'templates', 'database', 'github', 'jobs', 'email' ]
modules.forEach (m) ->
  require("./#{m}").initialise()

hapi = require 'hapi'
config = require '../config'
routes = require './routes'

port = process.env.PORT || 8080

server = hapi.createServer 'localhost', port,
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
  cache: config.sessions.development

routes.initialise server

console.log "server: awaiting connections on port #{port}"

server.start()

