
generate = require '@babel/generator'

parser = require 'cirru-parser'
scirpus = require 'scirpus'

exports.compile = (code, options) ->
  ast = parser.pare code
  IR = scirpus.transform ast
  res = generate.default IR, {presets: []}, code
  res.code
