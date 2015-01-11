
parser = require 'cirru-parser'
sourceMap = require 'source-map'

grammar = require './grammar'

{SourceMapGenerator} = sourceMap

assemble = (operation) ->
  bundleMap = new SourceMapGenerator file: 'demo'
  js = ''
  state =
    indent: 0
  js: js
  mapping: bundleMap.toJSON()

exports.compile = (code, filename="unknown") ->

  ast = parser.parse code, filename
  segments = grammar.resolve ast
  res = (assemble segments)
  console.log res
