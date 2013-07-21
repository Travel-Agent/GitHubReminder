'use strict'

module.exports =
  path: '/'
  method: 'GET'
  config:
    handler: ->
      this.reply.view 'content/index.html',
        repos: [
          'TODO: recently starred repos'
        ]
        isWeekly: 'TODO: isDaily / isWeekly / isMonthly based on existing settings'
        isSaved: 'TODO: true if reminders are enabled, false otherwise'
    auth: true

