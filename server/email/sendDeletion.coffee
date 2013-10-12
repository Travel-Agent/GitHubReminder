'use strict'

log = require '../log'

initialise = (transport, config, subjectPrefix) ->
  log = log.initialise 'email/deletion'
  log.info 'initialising'

  (event) ->
    { user, emailAddress, frequency, status } = event.getData()

    text = """
           Hey #{user},

           I received an HTTP #{status} response from GitHub when attempting to generate your #{frequency} email from GitHubReminder.

           Usually this happens when you revoke permissions for the GitHubReminder application in your GitHub account settings. For that reason, I've taken the liberty of deleting all your data from my database.

           If I have acted too hastily and you'd like to set up your reminders again, you will need to sign in here and save your settings:

           #{config.baseUri}signin

           Otherwise, you'll never hear from me again. I shall miss you and remember our time together fondly.

           So long,
           the reminder bot.
           """

    log.info "sending email to #{emailAddress}:"
    console.log text

    transport.sendMail {
      from: config.from
      to: emailAddress
      subject: "#{subjectPrefix} Your account has been deleted"
      text
    }, event.respond

module.exports = { initialise }

