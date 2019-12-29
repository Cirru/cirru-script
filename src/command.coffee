
fs = require 'fs'
path = require 'path'
repl = require 'repl'
vm = require 'vm'
m = require 'module'

compiler = require './compiler'

filename = process.argv[2]
seperator = '-----------------'

maybeShowJs = (js, filename) ->
  if process.env.DISPLAY_JS is 'true'
    console.log()
    console.log seperator, filename, seperator
    console.log()
    console.log js
    console.log()
    console.log seperator, filename, seperator
    console.log()


if filename?
  require('./register')

  mainModule = require.main
  mainModule.filename = filename = fs.realpathSync filename
  mainModule.moduleCache and= {}
  mainModule.paths = m._nodeModulePaths (path.dirname filename)
  code = fs.readFileSync filename, 'utf8'
  js = compiler.compile code

  maybeShowJs(js)

  mainModule._compile js, mainModule.filename

else
  repl.start
    prompt: 'cirru-script> '
    eval: (input, context, filename, cb) ->
      code = input[...-1]
      try
        js = compiler.compile code
        maybeShowJs js, 'REPL'
        cb null, (vm.runInContext js, context)

      catch err
        cb err
