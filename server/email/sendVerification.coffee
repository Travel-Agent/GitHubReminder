'use strict'

log = require '../log'

initialise = (transport, config, subjectPrefix) ->
  log = log.initialise 'email/verification'
  log.info 'initialising'

  (event) ->
    { user, emailAddress, token } = event.getData()

    text = """
           Hello,

           The email address #{emailAddress} has been registered on:

           #{config.baseUri}

           If this was not you or it was done in error, you can ignore this
           message. The email address will be removed from my database in
           24 hours.

           If you would like to verify the email address and activate your
           reminders, just GET the following URL within the next 24 hours:

           #{config.baseUri}verify-email?user=#{encodeURIComponent user}&token=#{encodeURIComponent token}

           Farewell,
           the reminder bot.
           """

    log.info "sending email to #{emailAddress}:"
    console.log text

    transport.sendMail {
      from: config.from
      to: emailAddress
      subject: "#{subjectPrefix} Verify email address"
      text
    }, event.respond

module.exports = { initialise }

