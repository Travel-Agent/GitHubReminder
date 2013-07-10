fs = require 'fs'
path = require 'path'
handlebars = require 'handlebars'

layoutPath = path.resolve __dirname, '../views/layout.html'

prepare = ->
  log 'registering helpers'

  handlebars.registerHelper 'block', blockHelper
  handlebars.registerHelper 'partial', partialHelper

  fs.readFile layoutPath, encoding: 'utf8', registerLayout

blockHelper = (name, options) ->
  if typeof handlebars.partials[name] is 'string'
    log "compiling partial #{name}"
    handlebars.partials[name] = handlebars.compile handlebars.partials[name]

  partial = handlebars.partials[name] || options.fn;

  log "rendering partial #{name}"
  partial this, data: options.hash

partialHelper = (name, options) ->
  log "registering partial #{name}"
  handlebars.registerPartial name, options.fn

registerLayout = (error, template) ->
  if error
    log "fatal error reading layout.html, `#{error}`"
    process.exit 1

  log 'registering layout partial'
  handlebars.registerPartial 'layout', handlebars.compile template

log = (message) ->
  console.log "server/templates: #{message}"

module.exports = { prepare }

