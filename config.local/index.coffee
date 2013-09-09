module.exports =
  cookies:
    password: 'TODO: A password for auth cookie encoding'
  sessions:
    engine: 'mongodb'
    partition: 'ghr_sessions'
    host: 'localhost'
    port: 27017
  oauth:
    uri: 'https://github.com/login/oauth/authorize'
    id: 'TODO: GitHub OAuth client id'
    scope: 'user:email'
    secret: 'TODO: GitHub OAuth client secret'
    route: '/oauth/github'
  database:
    host: 'localhost'
    port: 27017
    name: 'ghr'
  email:
    key: 'TODO: Amazon SES access key'
    secret: 'TODO: Amazon SES secret'
    from: 'reminderbot@githubreminder.org'
    errors: 'TODO: Recpient email address for error messages'
    baseUri: 'http://localhost:8080/'

