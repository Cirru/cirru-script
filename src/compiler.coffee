
generate = require '@babel/generator'

{ parse } = require '@cirru/parser.ts/'
scirpus = require 'scirpus'

exports.compile = (code, options) ->
  ast = parse code
  IR = scirpus.transform ast
  res = generate.default IR, {presets: []}, code
  res.code
