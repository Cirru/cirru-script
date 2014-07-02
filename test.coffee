
require 'shelljs/global'

code = cat './cirru/misc.cirru'
compiler = require './coffee/compiler.coffee'
compiled = compiler.compile code
compiled.to 'compiled/misc.js'