coffee = require 'coffee-script-redux'
coffee.register()

hapi = require 'hapi'
config = require '../config'

server = hapi.createServer 'localhost', 8000,
  views:
    path: 'views'
    engines:
      html: 'handlebars'
  auth:
    scheme: 'cookie'
    isSecure: false # TODO: Investigate SSL, set to true
    redirectTo: '/signin'
    appendNext: true

server.routes [
  {
    path: '/signin'
    method: 'GET'
    config:
      handler: ->
        if this.auth.isAuthenticated
          return thisreply.redirect '/'

        # TODO: Inherit from layout with http://thejohnfreeman.com/blog/2012/03/23/template-inheritance-for-handlebars.html
        this.reply.view 'content/signin.html'
          url: 'TODO: Create OAuth URL - see http://developer.github.com/v3/oauth'
      auth:
        mode: 'try'
  }
  {
    path: config.oauth.github.route
    method: 'GET'
    config:
      # TODO: Process this.query, set session cookie
      handler: ->
      auth: true
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

