coffee = require 'coffee-script-redux'
coffee.register()

fs = require 'fs'
path = require 'path'
hapi = require 'hapi'
handlebars = require 'handlebars'
config = require '../config'

handlebars.registerHelper 'block', (name, options) ->
  if typeof handlebars.partials[name] is 'string'
    handlebars.partials[name] = handlebars.compile handlebars.partials[name]

  partial = handlebars.partials[name] || options.fn;

  partial this, data: options.hash

handlebars.registerHelper 'partial', (name, options) ->
  handlebars.registerPartial name, options.fn

fs.readFile path.resolve(__dirname, '../views/layout.html'), encoding: 'utf8', (error, template) ->
  if error
    console.log "Fatal error reading layout.html: #{error}"
    process.exit 1
  else
    handlebars.registerPartial 'layout', handlebars.compile template

server = hapi.createServer 'localhost', 8000,
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

server.route [
  {
    path: '/signin'
    method: 'GET'
    config:
      handler: ->
        if this.auth.isAuthenticated
          return thisreply.redirect '/'

        this.reply.view 'content/signin.html',
          # TODO: Generate state on the fly? Would need to store states in db, along with http response code
          url: "#{config.oauth.github.uri}?client_id=#{config.oauth.github.id}&scope=#{config.oauth.github.scope}&state=#{config.oauth.github.state}"
      auth:
        mode: 'try'
  }
  {
    path: config.oauth.github.route
    method: 'GET'
    config:
      handler: ->
        # TODO: Check this.query.code?
        if this.query.client_id is config.oauth.github.id and this.query.client_secret is config.oauth.github.secret
          console.dir this
          # TODO: Fetch user from database, or create new user with default settings
          this.auth.session.set
            github: 'TODO: Get access_token from the request body'
          this.reply.redirect '/'

      auth: false
  }
  {
    path: '/signout'
    method: 'GET'
    config:
      handler: ->
        this.auth.session.clear()
        this.reply.redirect '/'
      auth: true
  }
  {
    path: '/'
    method: 'GET'
    config:
      handler: ->
        this.reply.view 'content/index.html',
          username: 'TODO
          repos: [
          ]
          isWeekly:
          isSaved:
      auth: true
  }
  {
    path: '/'
    method: 'POST'
    config:
      # TODO: Limit to same origin
      # TODO: Validate query parameters
      #   e.g
      #     validate:
      #       query:
      #         name: hapi.types.String().required()
      # TODO: Fetch starred repos - http://developer.github.com/v3/activity/starring
      # TODO: CRON
      handler: ->
      auth: true
  }
  {
    path: '/cancel'
    method: 'GET'
    config:
      handler: ->
      auth: true
  }
]

# TO SERVE STATIC CONTENT FROM public
#server.route
#  method: 'GET'
#  path: '/{path*}'
#  config:
#    handler:
#      directory:
#        path: 'public'
#        listing: false
#        index: true

server.start()

