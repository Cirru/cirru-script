
babel = require 'babel-core'
es2015 = require 'babel-preset-es2015'
parser = require 'cirru-parser'
scirpus = require 'scirpus'

exports.compile = (code, options) ->
  ast = parser.pare code
  IR = scirpus.transform ast
  res = babel.transformFromAst IR, code,
    presets: [es2015]
  res.code
