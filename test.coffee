
require 'shelljs/global'
mission = require 'mission'

compile = ->
  code = cat './cirru/misc.cirru'
  compiler = require './coffee/compiler.coffee'
  compiled = compiler.compile code
  compiled.to 'compiled/misc.js'

mission.watch
  file: 'cirru/'
  trigger: compile

compile()