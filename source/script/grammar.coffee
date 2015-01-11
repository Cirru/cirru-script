
_ = require 'lodash'

regVariable = /(\w|\$)[\$\w\d]*(\.(\w|\$)[\$\w\d]*)*/
regNumber = /^[+-\.]?[\d\.]+/

space = type: 'control', name: 'space'
newline = type: 'control', name: 'newline'
comma = type: 'control', name: 'comma'
semicolon = type: 'control', name: 'semicolon'
indent = type: 'control', name: 'indent'
unindent = type: 'control', name: 'unindent'

exports.resolve = (ast) ->
  decorateStatements (transformList ast)

transformExpr = (expr) ->
  if _.isArray expr
    if expr.length is 0 then throw  new Error 'got empty expression'
    head = expr[0]
    switch
      when head.text in ['+', '-', '*', '/']
        transformInfixMath expr
      when head.text in ['>', '==', '<', '&&', '||', '!']
        transformInfixOperator expr
      else
        handler = builtins[head.text]
        handler or= builtins['evaluate']
        handler expr
  else # token
    transformToken expr

transformToken = (expr) ->
  text = expr.text
  switch
    when text is 'true'
      type: 'segment', name: 'true', x: expr.x, y: expr.y
    when text is 'false'
      type: 'segment', name: 'false', x: expr.x, y: expr.y
    when text is 'undefined'
      type: 'segment', name: 'undefined', x: expr.x, y: expr.y
    when text is 'null'
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

transformInfixOperator = (expr) ->
  unless expr.length is 3
    throw new Error "infix operators accepts 2 arguments"
  head = expr[0]
  first = expr[1]
  second = expr[2]
  [
    transformExpr first
  ,
    space
  ,
    type: 'segment', name: head.text, x: head.x, y: head.y
  ,
    space
  ,
    transformExpr second
  ]

transformInfixMath = (expr) ->
  head = expr[0]
  tail = expr[1..]
  fold = (xs, list) ->
    if list.length is 0 then return xs
    if xs.length > 0
      xs = xs.concat space
      xs = xs.concat type: 'segment', name: head.text, x: head.x, y: head.y
      xs = xs.concat space
    first = list[0]
    newXs = xs.concat first
    fold newXs, list[1..]
  fold [], (tail.map transformExpr)

transformList = (list) ->
  list.map transformExpr

decorateStatements = (list) ->
  fold = (res, data) ->
    if data.length is 0 then return res
    res = res.concat [data[0]]
    res = res.concat semicolon
    res.push type: 'control', name: 'newline'
    fold res, data[1..]
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
      unless _.isObject(key) and key.text[0] is ':'
        throw new Error "a key starts with :"
      value = pair[1]
      [
        newline
      ,
        type: "segment", name: key.text[1..], x: key.x, y: key.y
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
    head = expr[0]
    content = expr[1]
    unless _.isObject content
      throw new Error '-- only supports text'
    [
      type: 'segment', name: '/* ', x: head.x, y: head.y
    ,
      type: 'segment', name: content.text, x: content.x, y: content.y
    ,
      type: 'segment', name: ' */', x: head.x, y: head.y
    ]

  '\\': (expr) ->
    head = expr[0]
    args = expr[1]
    unless _.isArray args
      throw new Error 'function arguments represents in an array'
    body = expr[2...-1]
    last = expr[expr.length-1]
    [
      type: 'segment', name: 'function(', x: head.x, y: head.y
      decorateArguments (transformList args)
      type: 'segment', name: ') {', x: head.x, y: head.y
      indent
      newline
      decorateStatements (transformList body)
      type: 'segment', name: 'return', x: head.x, y: head.y
      space
      transformExpr last
      semicolon
      unindent
      newline
      type: 'segment', name: '}', x: head.x, y: head.y
    ]

  regexp: (expr) ->
    reg = expr[1]
    unless _.isObject reg
      throw new Error '-- regexp only accepts token'
    type: 'segment', name: "/#{reg.text}/", x: reg.x, y: reg.y

  'new': (expr) ->
    head = expr[0]
    construct = expr[1]
    options = expr[2..]
    before = [
      type: 'segment', name: 'new', x: head.x, y: head.y
    ,
      space
    ,
      type: 'segment', name: construct.text, x: construct.x, y: construct.y
    ,
      type: 'segment', name: '(', x: head.x, y: head.y
    ,
      decorateArguments (transformList options)
    ,
      type: 'segment', name: ')', x: head.x, y: head.y
    ]

  '.': (expr) ->
    head = expr[0]
    dict = expr[1]
    key = expr[2]
    [
      transformExpr dict
    ,
      type: 'segment', name: '[', x: head.x, y: head.y
    ,
      transformExpr key
    ,
      type: 'segment', name: ']', x: head.x, y: head.y
    ]

  '?': (expr) ->
    head = expr[0]
    value = transformExpr expr[1]
    [
      type: 'segment', name: 'typeof ', x: head.x, y: head.y
      value
      type: 'segment', name: ' !== "undefined" && ', x: head.x, y: head.y
      value
      type: 'segment', name: ' !== null', x: head.x, y: head.y
    ]

  '?=': (expr) ->
    head = expr[0]
    variable = expr[1]
    value = expr[2]
    unless variable.text.match(regVariable)?
      throw new Error "path can not be assgined ==#{variable.text}=="
    [
      type: 'segment', name: 'if (', x: head.x, y: head.y
    ,
      type: 'segment', name: variable.text, x: variable.x, y: variable.y
    ,
      type: 'segment', name: ' == null) {', x: head.x, y: head.y
      indent
      newline
      type: 'segment', name: variable.text, x: variable.x, y: variable.y
      space
      type: 'segment', name: '=', x: head.x, y: head.y
      space
      transformExpr value
      semicolon
      unindent
      newline
      type: 'segment', name: '}', x: head.x, y: head.y
    ]

  '++:': (expr) ->
    head = expr[0]
    expr[1..].map (x, index) ->
      [
        type: 'segment', name: (if index is 0 then '\'\'+ ' else ' + " " + ')
        x: head.x, y: head.y
        transformExpr x
      ]
