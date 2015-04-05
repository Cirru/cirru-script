
parser = require 'cirru-parser'
scirpus = require 'scirpus'
babel = require 'babel-core/browser'

exports.compile = (code, options) ->
  ast = parser.pare code
  IR = scirpus.transform ast
  res = babel.fromAst IR, null, {}
  res.code
