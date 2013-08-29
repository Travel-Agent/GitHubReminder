'use strict'

initialise = (transport, config, subjectPrefix) ->
  (event) ->
    { to, frequency, repo, uris } = event.getData()
    transport.sendEmail {
      from: config.from
      to: to
      subject: "#{subjectPrefix} #{repo.name}"
      text: """
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
    }, event.respond

module.exports = { initialise }

