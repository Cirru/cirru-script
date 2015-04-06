
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
  mainModule.paths = m._nodeModulePaths (path.dirname filename)
  code = fs.readFileSync filename, 'utf8'
  js = compiler.compile code
  mainModule._compile js, mainModule.filename

else
  repl.start
    prompt: 'cirru-script> '
    eval: (input, context, filename, cb) ->
      code = input[1...-1]
      try
        js = compiler.compile code
        cb null, (vm.runInContext js, context)

      catch err
        cb err

