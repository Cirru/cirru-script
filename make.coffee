
require 'shelljs/make'
mission = require 'mission'

target.test = ->
  station = mission.reload()

  mission.watch
    file: ['compiled/']
    trigger: (filename, extname) ->
      station.reload 'repo/Cirru/cirru-js/'

  exec 'node-dev test.coffee', async: yes