'use strict'

module.exports =
  path: '/{path*}'
  method: 'GET'
  config:
    handler:
      directory:
        path: 'public'
        listing: false
        index: true

