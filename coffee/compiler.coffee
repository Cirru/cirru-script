
grammar = require './grammar'
cirru = require 'cirru-parser'

exports.compile = (code) ->
  ast = cirru.pare code
  env =
    expr: no
    vars: []
    add: (name) ->
      unless name in @vars
        @vars.push name
    spawn: (opts) ->
      child =
        expr: yes
        vars: @vars.concat()
        spawn: @spawn
        add: @add
      if opts? then child.expr = opts.expr
      child

  codeList = ast
  .map (expr) ->
    grammar.expand expr, env

  codeList.join('')