
_ = require 'lodash'

Env = require './env'
State = require './state'

regVariable = /(\w|\$)[\$\w\d]*(\.(\w|\$)[\$\w\d]*)*/
regNumber = /^[+-\.]?[\d\.]+/

space     = type: 'control', name: 'space'
newline   = type: 'control', name: 'newline'
comma     = type: 'control', name: 'comma'
semicolon = type: 'control', name: 'semicolon'
indent    = type: 'control', name: 'indent'
unindent  = type: 'control', name: 'unindent'

S = (code, target) ->
  type: 'segment', name: S, x: target.x, y: target.y

exports.resolve = (ast) ->
  topEnv = new Env null
  topState = new State
  pos = 0
  transformList ast, topEnv, topState, pos

transformExpr = (expr, env, state, pos) ->
  if _.isArray expr
    if expr.length is 0 then throw  new Error 'got empty expression'
    head = expr[0]
    res = switch
      when head.text in ['+', '-', '*', '/']
        transformInfixMath expr, env, state, pos
      when head.text in ['>', '==', '<', '&&', '||', '!']
        transformInfixOperator expr, env, state, pos
      else
        handler = builtins[head.text]
        handler or= builtins['evaluate']
        handler expr, env, state, pos
    res
  else # token
    transformToken expr, env, state, pos

transformToken = (expr, env, state, pos) ->
  text = expr.text
  switch
    when text in ['true', 'false', 'undefined', 'null', 'continute', 'break', 'debugger']
      S text, expr
    when text[0] is ':'
      stringValue = "'#{(JSON.stringify text[1..])[1...-1]}'"
      S stringValue, expr
    when text[0] is '/'
      S "/#{text[1..]}/", expr
    when text[0].match(regNumber)?
      numberValue = parseFloat(text).toString()
      S numberValue, expr
    when text[0].match(regVariable)?
      S text, expr
    else
      throw new Error "can recognize ==#{expr.text}=="

transformInfixOperator = (expr, env, state, pos) ->
  unless expr.length is 3
    throw new Error "infix operators accepts 2 arguments"
  head = expr[0]
  first = expr[1]
  second = expr[2]
  [
    transformExpr first, env, state, pos
    space
    S head.text, head
    transformExpr second, env
  ]

transformInfixMath = (expr, env, state, pos) ->
  head = expr[0]
  tail = expr[1..]
  fold = (xs, list) ->
    if list.length is 0 then return xs
    if xs.length > 0
      xs = xs.concat space
      xs = xs.concat (S head.text, head)
      xs = xs.concat space
    first = list[0]
    newXs = xs.concat first
    fold newXs, list[1..]
  fold [], (tail.map (x, pos) -> transformExpr x, env, state, pos)

transformList = (list, env, state, pos) ->
  list.map (expr, pos) ->
    transformExpr expr, env, state, pos

builtins =
  '=': (expr, env, state, pos) ->
    head = expr[0]
    variable = expr[1]
    unless variable.text.match(regVariable)?
      throw new Error "path can not be assgined ==#{variable.text}=="
    segmentVar = S variable.text, variable
    env.registerVar segmentVar
    [
      segmentVar
      space
      S '=', head
      space
      transformExpr expr[2], env, state, pos
    ]

  'evaluate': (expr, env, state, pos) ->
    head = expr[0]
    unless head.text.match(regVariable)
      throw new Error "can not evaluate #{head.text}"
    tail = expr[1..]
    [
      S head.text, head
      S '(', head
      transformList tail, env, state, pos
      S ')', head
    ]

  'array': (expr, env, state, pos) ->
    head = expr[0]
    tail = expr[1..]
    [
      S '[', head
      transformList tail, env, state, pos
      S ']', head
    ]

  'object': (expr, env, state, pos) ->
    head = expr[0]
    pairs = expr[1..].map (pair) ->
      key = pair[0]
      unless _.isObject(key) and key.text[0] is ':'
        throw new Error "a key starts with :"
      value = pair[1]
      [
        newline
        S key.text[1..], key
        S ':', head
        space
        transformExpr value, env, state, pos
        S ',', head
      ]
    [
      S '{', head
      indent
      pairs
      unindent
      newline
      S '}', head
    ]

  '--': (expr, env, state, pos) ->
    head = expr[0]
    content = expr[1]
    unless _.isObject content
      throw new Error '-- only supports text'
    [
      S '/* ', head
      S content.text, content
      S ' */', head
    ]

  '\\': (expr, env, state, pos) ->
    head = expr[0]
    args = expr[1]
    unless _.isArray args
      throw new Error 'function arguments represents in an array'
    body = expr[2...-1]
    last = expr[expr.length-1]
    [
      S 'function(', head
      transformList args, env, state, pos
      S ') {', head
      indent
      transformList body, env, state, pos
      newline
      S 'return', head
      space
      transformExpr last, env, state, pos
      semicolon
      unindent
      newline
      S '}', head
    ]

  'new': (expr, env, state, pos) ->
    head = expr[0]
    construct = expr[1]
    options = expr[2..]
    before = [
      S 'new', head
      space
      S construct.text, construct
      S '(', head
      transformList options, env, state, pos
      S ')', head
    ]

  '.': (expr, env, state, pos) ->
    head = expr[0]
    dict = expr[1]
    key = expr[2]
    [
      transformExpr dict, env, state, pos
      S '[', head
      transformExpr key, env, state, pos
      S ']', head
    ]

  '?': (expr, env, state, pos) ->
    head = expr[0]
    value = transformExpr expr[1], env, state, pos
    [
      S 'typeof ', head
      value
      S ' !== "undefined" && ', head
      value
      S ' !== null', head
    ]

  '?=': (expr, env, state, pos) ->
    head = expr[0]
    variable = expr[1]
    value = expr[2]
    unless variable.text.match(regVariable)?
      throw new Error "path can not be assgined ==#{variable.text}=="
    [
      S 'if (', head
      S variable.text, variable
      S ' == null) {', head.x
      indent
      newline
      S variable.text, variable
      space
      S '=', head
      space
      transformExpr value, env, state, pos
      semicolon
      unindent
      newline
      S '}', head
    ]

  '++:': (expr, env, state, pos) ->
    head = expr[0]
    expr[1..].map (x, index) ->
      [
        S (if index is 0 then '\'\'+ ' else ' + " " + '), head
        transformExpr x, env, state, pos
      ]

  'while': (expr, env, state, pos) ->
    head = expr[0]
    cond = expr[1]
    body = expr[2..]
    [
      S 'while (', head
      transformExpr cond, env, state, pos
      S ') {', head
      indent
      transformList body, env, state, pos
      unindent
      newline
      S '}', head
    ]

  'for': (expr, env, state, pos) ->
    head = expr[0]
    cond = expr[1]
    body = expr[2..]
    refVar = env.makeRefN head
    lenVar = env.makeLenN head
    unless _.isArray(cond) and (cond.length is 3)
      throw new Error 'cond should an array which leng is 3'
    variable = cond[0]
    key = cond[1]
    value = cond[2]
    env.registerVar key
    env.registerVar value
    [
      newline
      refVar
      S ' = ', head
      transformExpr cond, env, state, pos
      semicolon
      newline
      S 'for( ', head
      S key.text, key
      S ' = 0, ', head
      S lenVar.text, lenVar
      S ' = '
      S variable.text, variable
      S '.length; '
      S key.text, key
      S ' < ', head
      S lenVar.text, lenVar
      semicolon
      space
      S key.text, key
      S '++) {', head
      indent
      newline
      S value.text, value
      S ' = ', head
      S variable.text, value
      S '[', head
      S key.text, key
      S ']', head
      unindent
      newline
      S '}', head
    ]