fs = require 'fs'
path = require 'path'

initialise = (server) ->
  getFileNames().filter(isDefinitionModule).sort().forEach (fileName) ->
    server.route require "./#{fileName}"

getFileNames = ->
  fs.readdirSync __dirname

isDefinitionModule = (fileName) ->
  if fs.statSync(path.resolve __dirname, fileName).isFile()
    components = fileName.split '.'
    return components.length is 2 and components[0] isnt 'index' and components[1] is 'coffee'

  false

module.exports = { initialise }

