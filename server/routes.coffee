config = require '../config'

# TODO: Break each route into a separate module?

initialise = (server) ->
  server.route [
    {
      path: '/signin'
      method: 'GET'
      config:
        handler: ->
          if this.auth.isAuthenticated
            return thisreply.redirect '/'

          this.reply.view 'content/signin.html',
            # TODO: Generate state on the fly? Would need to store states in db
            url: "#{config.oauth.github.uri}?client_id=#{config.oauth.github.id}&scope=#{config.oauth.github.scope}&state=#{config.oauth.github.state}"
        auth:
          mode: 'try'
    }
    {
      path: config.oauth.github.route
      method: 'GET'
      config:
        handler: ->
          if this.query.state is config.oauth.github.state
            console.dir this
            # TODO: Fetch user from database, or create new user with default settings
            this.auth.session.set
              github: this.query.code
            this.reply.redirect '/'

        auth:
          mode: 'try'
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
            username: 'TODO: user name'
            repos: [
              'TODO: recently starred repos'
            ]
            isWeekly: 'TODO: isDaily / isWeekly / isMonthly based on existing settings'
            isSaved: 'TODO: true if reminders are enabled, false otherwise'
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

  # TODO: Unsubscribe link

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

module.exports = { initialise }

