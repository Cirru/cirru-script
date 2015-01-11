
_ = require 'lodash'

regVariable = /\w[\w\d]*(\.\w[\w\d]*)*/
regNumber = /^[+-\.]?[\d\.]+/

space = type: 'control', name: 'space'
newline = type: 'control', name: 'newline'

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
        type: 'segment', name: 'true', x: expr.x, y: expr:y
      when text is '#false'
        type: 'segment', name: 'false', x: expr.x, y: expr.y
      when text is 'undefined'
        type: 'segment', name: 'undefined', x: expr.x, y: expr.y
      when text is 'null'
        type: 'segment', name: 'null', x: expr.x, y: expr.y
      when text[0] is ':'
        stringValue = "'#{JSON.stringify text[1..]}'"
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
      res.push type: 'control', name: 'argument-seperator'
    head = data[0]
    newRes = res.concat [head]
    fold newRes, data[1..]
  fold [], list

builtins =
  '=': (expr) ->
    head = expr[0]
    variable = expr[1]
    unless variable.text.match(regVariable)?
      throw new Erorr "path can not be assgined ==#{variable.text}=="
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
