
fs = require 'fs'

compiler = require './compiler'

seperator = '-----------------'

if require.extensions?
  require.extensions['.cirru'] = (module, filename) ->
    code = fs.readFileSync filename, 'utf8'
    js = compiler.compile code

    if process.env.DISPLAY_JS is 'true'
      console.log()
      console.log seperator, filename, seperator
      console.log()
      console.log js
      console.log()
      console.log seperator, filename, seperator
      console.log()

    module._compile js, filename
