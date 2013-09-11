'use strict'

log = require '../log'

initialise = (transport, config, subjectPrefix) ->
  log = log.initialise 'email/reminder'
  log.info 'initialising'

  (event) ->
    { to, user, frequency, repo, paths } = event.getData()

    text = """
           Hey #{user},

           This is your #{frequency} email from GitHubReminder. Your starred repo
           of the day is called #{repo.name}.

           Repository: #{repo.full_name}
           Description: #{repo.description || ''}
           Language: #{repo.language || ''}
           Stars: #{repo.watchers_count}
           Forks: #{repo.forks_count}

           #{repo.html_url}

           Cheerio,
           the reminder bot.

           --
           To change your settings:
           #{config.baseUri}#{paths.settings}

           To unsubscribe from these emails:
           #{config.baseUri}#{paths.unsubscribe}

           To unsubscribe and remove all of your data from my database:
           #{config.baseUri}#{paths.clobber}
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

