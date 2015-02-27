
fs = require 'fs'

compiler = require './compiler'

if require.extensions?
  require.extensions['.cirru'] = (module, filename) ->
    code = fs.readFileSync filename, 'utf8'
    res = compiler.compile code,
      path: filename
      relativePath: filename
    module._compile res.js, filename
  console.log require.extensions
