'use strict'

module.exports = { initialise }

initialise = (transport, config, subjectPrefix) ->
  (event) ->
    { emailAddress, token } = event.getData()
    transport.sendEmail {
      from: config.from
      to: emailAddress
      subject: "#{subjectPrefix} Verify email address"
      text: """
            Hello,

            The email address `#{emailAddress}` has been registered on:

            http://githubreminder.org/

            If this was not you or it was done in error, you can ignore this
            message. The email address will be removed from my database in
            24 hours.

            If you would like to verify the email address and activate your
            reminders, just GET the following URL within the next 24 hours:

            http://githubreminder.org/verify-email?address=#{encodeURIComponent emailAddress}&token=#{token}

            Goodbye,
            the reminder bot.
            """
    }, event.respond

