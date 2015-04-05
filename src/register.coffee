
fs = require 'fs'

compiler = require './compiler'

if require.extensions?
  require.extensions['.cirru'] = (module, filename) ->
    code = fs.readFileSync filename, 'utf8'
    js = compiler.compile code
    module._compile js, filename
