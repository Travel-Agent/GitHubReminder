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

# TODO: Once SSL is set up, pass options for this with isSecure: true
#server.state 'session',
#  encoding: 'base64json'

server.pack.allow(ext: true).require 'yar', {
  password: config.cookies.password
  isSecure: false # TODO: Investigate SSL, set to true
}, (error) ->
  if error
    console.log "server: error initialising cookies `#{error}`"
    process.exit 1

  routes.initialise server

  console.log "server: awaiting connections on port #{port}"
  server.start()

