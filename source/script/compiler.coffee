
parser = require 'cirru-parser'
sourceMap = require 'source-map'
_ = require 'lodash'

grammar = require './grammar'

{SourceMapGenerator} = sourceMap

assemble = (operations) ->
  operations = (_.flatten operations)
  operations = operations.filter _.isObject
  operations = operations.map (x) ->
    if x.type is 'declaration'
      x.getSegments()
    else x
  operations = (_.flatten operations)
  bundleMap = new SourceMapGenerator file: 'demo'
  js = ''
  state =
    indent: 1
    x: 1
    y: 1
  for index, op of operations
    if op.type is 'segment'
      js += op.name
      bundleMap.addMapping
        generated: {column: (state.x - 1), line: state.y}
        original: {column: (op.x - 1), line: op.y}
        source: 'demo'
        name: op.name
      state.x += op.name.length
      continue
    # so, it's supposed to be control
    switch op.name
      when 'indent' then state.indent += 2
      when 'unindent' then state.indent -= 2
      when 'space' then js += ' '; state.x += 1
      when 'comma' then js += ','; state.x += 1
      when 'semicolon' then js += ';'; state.x += 1
      when '(' then js += '('; state.x += 1
      when ')' then js += ')'; state.x += 1
      when 'var' then js += 'var'; state.x += 3
      when 'return' then js += 'return '; state.x += 7
      when 'newline'
        js += '\n'
        state.y += 1
        js += makeSpace (state.indent - 1)
        state.x = state.indent
      else throw new Error "unknown operation #{op}"
  # returns
  js: js
  mapping: bundleMap.toJSON()

exports.compile = (code, filename="unknown") ->

  ast = parser.parse code, filename
  segments = grammar.resolve ast
  res = (assemble segments)
  console.log res
  res

makeSpace = (level) ->
  fold = (xs, n) ->
    if n is 0 then xs else (' ' + fold(xs, (n-1)))
  fold '', level