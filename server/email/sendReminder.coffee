'use strict'

log = require '../log'

initialise = (transport, config, subjectPrefix) ->
  log = log.initialise 'email/reminder'
  log.info 'initialising'

  (event) ->
    { to, frequency, repo, uris } = event.getData()

    text = """
           Hello,

           This is your #{frequency} GitHub reminder.

           #{repo.full_name}

           #{repo.description}

           Language: #{repo.language}
           Stars: #{repo.watchers_count}
           Forks: #{repo.forks_count}

           #{repo.html_url}

           Cheerio,
           the reminder bot.

           To change your settings:

           #{uris.settings}

           To unsubscribe from these emails:

           #{uris.unsubscribe}

           To unsubscribe and remove all of your data from my database:

           #{uris.clobber}
           """

    log.info "sending email to #{to}:"
    console.log text

    transport.sendMail {
      from: config.from
      to
      subject: "#{subjectPrefix} #{repo.name}"
      text
    }, event.respond

module.exports = { initialise }

