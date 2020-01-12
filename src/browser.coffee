
babel = require '@babel/standalone'
parser = require 'cirru-parser'
scirpus = require 'scirpus'

exports.compile = (code, options) ->
  ast = parser.pare code
  IR = scirpus.transform ast
  res = babel.transformFromAst IR, code,
    presets: []
  res.code
