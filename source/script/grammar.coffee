
_ = require 'lodash'

regVariable = /(\w|\$)[\$\w\d]*(\.(\w|\$)[\$\w\d]*)*/
regNumber = /^[+-\.]?[\d\.]+/

space = type: 'control', name: 'space'
newline = type: 'control', name: 'newline'
indent = type: 'control', name: 'indent'
unindent = type: 'control', name: 'unindent'

exports.resolve = (ast) ->
  decorateStatements (transformList ast)

transformExpr = (expr) ->
  if _.isArray expr
    if expr.length is 0 then throw  new Error 'got empty expression'
    head = expr[0]
    handler = builtins[head.text]
    handler or= builtins['evaluate']
    handler expr
  else # token
    text = expr.text
    switch
      when text is '#true'
        type: 'segment', name: 'true', x: expr.x, y: expr.y
      when text is '#false'
        type: 'segment', name: 'false', x: expr.x, y: expr.y
      when text is '#undefined'
        type: 'segment', name: 'undefined', x: expr.x, y: expr.y
      when text is '#null'
        type: 'segment', name: 'null', x: expr.x, y: expr.y
      when text[0] is ':'
        stringValue = "'#{(JSON.stringify text[1..])[1...-1]}'"
        type: 'segment', name: stringValue, x: expr.x, y: expr.y
      when text[0].match(regNumber)?
        numberValue = parseFloat(text).toString()
        type: 'segment', name: numberValue, x: expr.x, y: expr.y
      when text[0].match(regVariable)?
        type: 'segment', name: text, x: expr.x, y: expr.y
      else
        throw new Error "can recognize ==#{expr.text}=="

transformList = (list) ->
  list.map transformExpr

decorateStatements = (list) ->
  fold = (res, data) ->
    if data.length is 0 then return res
    if res.length > 0
      res.push type: 'control', name: 'newline'
    head = data[0]
    newRes = res.concat [head]
    fold newRes, data[1..]
  fold [], list

decorateArguments = (list) ->
  fold = (res, data) ->
    if data.length is 0 then return res
    if res.length > 0
      res.push type: 'control', name: 'comma'
      res.push type: 'control', name: 'space'
    head = data[0]
    newRes = res.concat [head]
    fold newRes, data[1..]
  fold [], list

builtins =
  '=': (expr) ->
    head = expr[0]
    variable = expr[1]
    unless variable.text.match(regVariable)?
      throw new Error "path can not be assgined ==#{variable.text}=="
    [
      type: 'segment', name: variable.text, x: variable.x, y: variable.y
    ,
      space
    ,
      type: 'segment', name: '=', x: head.x, y: head.y
    ,
      space
    ,
      transformExpr expr[2]
    ]

  'evaluate': (expr) ->
    head = expr[0]
    unless head.text.match(regVariable)
      throw new Error "can not evaluate #{head.text}"
    tail = expr[1..]
    [
      type: 'segment', name: head.text, x: head.x, y: head.y
    ,
      type: 'segment', name: '(', x: head.x, y: head.y
    ,
      decorateArguments (transformList tail)
    ,
      type: 'segment', name: ')', x: head.x, y: head.y
    ]

  'array': (expr) ->
    head = expr[0]
    tail = expr[1..]
    [
      type: 'segment', name: '[', x: head.x, y: head.y
    ,
      decorateArguments (transformList tail)
    ,
      type: 'segment', name: ']', x: head.x, y: head.y
    ]

  'object': (expr) ->
    head = expr[0]
    pairs = expr[1..].map (pair) ->
      key = pair[0]
      unless _.isObject(key) then throw new Error
      value = pair[1]
      [
        newline
      ,
        type: "segment", name: key.text, x: head.x, y: head.y
      ,
        type: 'segment', name: ':', x: head.x, y: head.y
      ,
        space
      ,
        transformExpr value
      ,
        type: 'segment', name: ',', x: head.x, y: head.y
      ]
    [
      type: 'segment', name: '{', x: head.x, y: head.y
    ,
      indent
    ,
      pairs
    ,
      unindent
    ,
      newline
    ,
      type: 'segment', name: '}', x: head.x, y: head.y
    ]

  '--': (expr) ->
    content = expr[1]
    unless _.isObject content
      throw new Error '-- only supports text'
    type: 'segment', name: "/* #{content.text} */", x: content.x, y: content.y

  '\\': (expr) ->

  regexp: (expr) ->
    reg = expr[1]
    unless _.isObject reg
      throw new Error '-- regexp only accepts token'
    type: 'segment', name: reg.text, x: reg.x, y: reg.y

