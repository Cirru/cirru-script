
fs = require 'fs'
repl = require 'repl'
vm = require 'vm'

compiler = require './compiler'

filename = process.argv[2]

if filename?
  require('./register')

  mainModule = require.main
  mainModule.filename = filename = fs.realpathSync filename
  mainModule.moduleCache and= {}
  code = fs.readFileSync filename, 'utf8'
  res = compiler.compile code,
    path: filename
    relativePath: filename
  mainModule._compile res.js, mainModule.filename

else
  repl.start
    prompt: 'cirru-script> '
    eval: (input, context, filename, cb) ->
      code = input[1...-1]
      try
        res = compiler.compile code,
          path: filename
          relativePath: filename

        cb null, (vm.runInThisContext res.js, filename)

      catch err
        cb err
