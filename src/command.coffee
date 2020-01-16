
fs = require 'fs'
path = require 'path'
repl = require 'repl'
vm = require 'vm'
m = require 'module'
chalk = require 'chalk'

compiler = require './compiler'

seperator = '-----------------'

DISPLAY_JS = process.env.DISPLAY_JS is 'true'

maybeShowJs = (js, filename) ->
  if DISPLAY_JS
    console.log chalk.gray(js)

getAllCirruFiles = (x) ->
  if fs.statSync(x).isFile()
    if x.match(/\.cirru$/)
      return [x]
    else
      return []
  else
    children = fs.readdirSync x
    children
      .flatMap (child) ->
        if child is 'node_modules'
          return []
        else
          childPath = path.join x, child
          getAllCirruFiles childPath

if process.argv[2] is 'compile'
  fromDir = process.argv[3]
  toDir = process.argv[4]

  if not fromDir? or not toDir?
    console.log "cirruscript compile {from dir} {to dir}"
    process.exit 1

  baseFolder = path.join process.env.PWD, fromDir

  allCirruFiles = getAllCirruFiles baseFolder
  allCirruFiles.forEach (x) ->
    code = fs.readFileSync x, 'utf8'
    js = compiler.compile code
    relativeOne = path.relative baseFolder, x
    toFilepath = (path.join process.env.PWD, toDir, relativeOne).replace /\.cirru$/, '.js'
    fs.mkdirSync (path.dirname toFilepath), recursive: true, (err) ->
      console.log err
    fs.writeFileSync toFilepath, js
    console.log (path.relative process.env.PWD, x), '\t->\t', (path.relative process.env.PWD, toFilepath)

else if process.argv[2]?
  filename = process.argv[2]
  fullpath = path.join process.env.PWD, filename

  if not fs.existsSync(fullpath)
    console.log "Found no file", fullpath
    process.exit 1

  if fs.statSync(fullpath).isDirectory()
    console.log fullpath, "is a directory. No evaling."
    process.exit 1

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
  console.log()
  console.log chalk.gray "  Welcome to CirruScript! ."
  console.log chalk.gray "  Find more at http://script.cirru.org ."
  console.log chalk.gray "  Press Command D when you want to exit."
  console.log chalk.gray "  Use DISPLAY_JS=true for displaying generated js."
  console.log()

  clipboardy = require 'clipboardy'
  copy = (x) ->
    content = if typeof x is 'string' then x else (JSON.stringify x, null, 2)
    clipboardy.writeSync content
    console.log chalk.cyan content

  instance = repl.start
    prompt: chalk.bold 'cirruscript> '
    eval: (input, context, filename, cb) ->
      code = input[...-1]
      try
        js = compiler.compile code
        maybeShowJs js, 'REPL'
        cb null, (vm.runInContext js, context)

      catch err
        cb err

  instance.context.console.copy = copy
  instance.context.console.DISPLAY_JS = (x) -> DISPLAY_JS = x
