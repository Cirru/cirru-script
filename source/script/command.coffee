
fs = require 'fs'
path = require 'path'
repl = require 'repl'
vm = require 'vm'
m = require 'module'

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

        dir = process.env.PWD
        file = path.join dir, 'repl'
        # https://github.com/joyent/node/issues/9211
        f = vm.runInThisContext m.wrap(res.js), filename

        cb null, (f exports, require, module, file, dir)

      catch err
        cb err

