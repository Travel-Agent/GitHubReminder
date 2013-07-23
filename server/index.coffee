coffee = require 'coffee-script-redux'
coffee.register()

database = require './database'
database.initialise()

github = require './github'
github.initialise()

templates = require './templates'
templates.initialise()

hapi = require 'hapi'
config = require '../config'
routes = require './routes'

port = 8080

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
  cache: config.sessions.development

routes.initialise server

console.log "server: awaiting connections on port #{port}"

server.start()

