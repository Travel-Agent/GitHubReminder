coffee = require 'coffee-script-redux'
coffee.register()

templates = require './templates'
templates.prepare()

hapi = require 'hapi'
config = require '../config'
routes = require './routes'

port = 80

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
    appendNext: true

routes.initialise server

console.log "Awaiting connections on port #{port}'

server.start()

