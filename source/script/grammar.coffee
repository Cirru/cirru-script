
_ = require 'lodash'

Env = require './env'
alias = require './alias'

regVariable = /^@?(\w|\$)[\$\w\d]*(\.(\w|\$)[\$\w\d]*)*$/
regNumber = /^[+-\.]?[\d\.]+/

space     = type: 'control', name: 'space'
newline   = type: 'control', name: 'newline'
comma     = type: 'control', name: 'comma'
semicolon = type: 'control', name: 'semicolon'
indent    = type: 'control', name: 'indent'
unindent  = type: 'control', name: 'unindent'

S = (code, target) ->
  type: 'segment', name: code, x: target.x, y: target.y

safeKey = (text) ->
  if text.match(/^\w[\w\d]*$/) then text else "'#{text}'"

exports.resolve = (ast) ->
  topEnv = new Env null
  topState =
    position: 'statement'
    wantReturn: false
    rewriteThis: false
  pos = 0
  res = transformList ast, topEnv, topState
  [
    topEnv
    res
    newline
  ]

transformExpr = (expr, env, state, pos) ->
  if _.isArray expr
    if expr.length is 0 then throw  new Error 'got empty expression'
    head = expr[0]
    alias.rewrite head
    insideState =
      position: 'inline'
      wantReturn: state.wantReturn
      parentLength: state.parentLength
      rewriteThis: state.rewriteThis

    res = switch
      when head.text in ['+', '-', '*', '/']
        transformInfixMath expr, env, insideState
      when head.text in ['>', '!==', '===', '<', '&&', '||', '>=', '<=']
        transformInfixOperator expr, env, insideState
      else
        handler = builtins[head.text]
        handler or= builtins['evaluate']
        handler expr, env, insideState, pos, state
    type = 'expr'
  else # token
    res = transformToken expr, env, state
    type = 'token'
  hasBlock = expr[0]?.text in [
    'for', 'while', 'if', '?=', 'lambda', 'switch', 'cond', 'try'
  ]
  if (state.position is 'inline') and (type is 'expr') and (not state.bracketFree)
    res = [
      type: 'control', name: '('
      res
      type: 'control', name: ')'
    ]
  if (state.position is 'inlineList') and (pos > 0)
    res = [
      comma
      space
      res
    ]
  if state.wantReturn and ((pos + 1) is state.parentLength)
    unless head?.text in ['if', 'switch', 'cond', 'try', 'for']
      unless res[0]?.name in ['return ', 'return']
        res = [
          type: 'control', name: 'return'
          res
        ]
  if (state.position is 'statement')
    res = [
      newline
      res
      semicolon unless hasBlock
    ]
  res

transformToken = (expr, env, state) ->
  text = expr.text
  if state.rewriteThis
    text = text.replace /^this\./, '_this.'
    text = text.replace /^\@/, '_this.'
  else
    text = text.replace /^\@/, 'this.'
  switch
    when text in ['true', 'false', 'undefined', 'null', 'continute', 'break', 'debugger']
      S text, expr
    when text[0] is ':'
      stringValue = "'#{(JSON.stringify text[1..])[1...-1]}'"
      S stringValue, expr
    when text[0] is '/'
      S "/#{text[1..]}/", expr
    when text.match(regNumber)?
      numberValue = parseFloat(text).toString()
      S numberValue, expr
    when text.match(regVariable)?
      S text, expr
    else
      throw new Error "does not recognize ==#{expr.text}=="

transformInfixOperator = (expr, env, state) ->
  unless expr.length is 3
    throw new Error "infix operators accepts 2 arguments"
  head = expr[0]
  first = expr[1]
  second = expr[2]
  insideState =
    position: 'inline'
    wantReturn: no
    rewriteThis: state.rewriteThis
  [
    transformExpr first, env, insideState
    space
    S head.text, head
    space
    transformExpr second, env, insideState
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
  insideState =
    position: 'inline'
    wantReturn: false
    rewrite: state.rewriteThis
  fold [], (tail.map (x) -> transformExpr x, env, insideState)

transformList = (list, env, state) ->
  state.parentLength = list.length
  list.map (expr, pos) ->
    newState = _.clone state
    if (pos + 1) isnt list.length
      newState.wantReturn = false
    transformExpr expr, env, newState, pos

builtins =
  'set': (expr, env, state) ->
    head = expr[0]
    variable = expr[1]
    insideState =
      position: 'inline'
      wantReturn: false
      bracketFree: yes
      rewriteThis: state.rewriteThis
    segmentVar = transformExpr variable, env, insideState
    unless _.isArray variable
      env.registerVar segmentVar
    [
      segmentVar
      S ' = ', head
      transformExpr expr[2], env, insideState
    ]

  'evaluate': (expr, env, state) ->
    head = expr[0]
    nameState =
      position: 'inline'
      wantReturn: false
      bracketFree: false
      rewriteThis: state.rewriteThis
    insideState =
      position: 'inlineList'
      wantReturn: false
      bracketFree: yes
      rewriteThis: state.rewriteThis
    unless head.text.match(regVariable)
      throw new Error "can not evaluate #{head.text}"
    tail = expr[1..]
    [
      transformExpr head, env, nameState
      S '(', head
      transformList tail, env, insideState
      S ')', head
    ]

  'array': (expr, env, state) ->
    head = expr[0]
    tail = expr[1..]
    insideState =
      position: 'inlineList'
      wantReturn: false
      bracketFree: false
      rewriteThis: state.rewriteThis
    [
      S '[', head
      transformList tail, env, insideState
      S ']', head
    ]

  'object': (expr, env, state) ->
    head = expr[0]
    body = expr[1..]
    insideState =
      position: 'inline'
      wantReturn: false
      bracketFree: true
      rewriteThis: state.rewriteThis
    pairs = body.map (pair, index) ->
      key = pair[0]
      unless _.isObject(key) and key.text[0] is ':'
        throw new Error "a key starts with :"
      value = pair[1]
      [
        newline
        S (safeKey key.text[1..]), key
        S ':', head
        space
        transformExpr value, env, insideState
        S ',', head unless (index + 1) is body.length
      ]
    [
      S '{', head
      indent
      pairs
      unindent
      newline
      S '}', head
    ]

  '--': (expr, env) ->
    head = expr[0]
    content = expr[1]
    unless _.isObject content
      throw new Error '-- only supports text'
    [
      S '/* ', head
      S content.text, content
      S ' */', head
    ]

  'lambda': (expr, env, state, pos, outsideState) ->
    head = expr[0]
    args = expr[1]
    insideEnv = new Env env
    argsState =
      position: 'inlineList'
      wantReturn: no
      bracketFree: false
      rewriteThis: state.rewriteThis
    insideState =
      position: 'statement'
      wantReturn: not outsideState.nameSegment?
      bracketFree: false
      rewriteThis: state.rewriteThis
    normalArgs = _.isArray args
    if normalArgs
      args.map (x) -> insideEnv.markArgs x.text
    else
      insideEnv.registerVar (S args.text, args)
    body = expr[2..]
    [
      S 'function ', head
      if outsideState.nameSegment?
        outsideState.nameSegment
      S '(', head
      if normalArgs then transformList args, env, argsState
      S ') {', head
      indent
      insideEnv
      unless normalArgs then [
        newline
        S args.text, args
        S ' = [].slice.call(arguments, 0)', head
        semicolon
      ]
      transformList body, insideEnv, insideState
      unindent
      newline
      S '}', head
    ]

  '\\=': (expr, env, state) ->
    head = expr[0]
    args = expr[1]
    insideEnv = new Env env
    argsState =
      position: 'inlineList'
      wantReturn: no
      bracketFree: false
      rewriteThis: state.rewriteThis
    insideState =
      position: 'statement'
      wantReturn: yes
      bracketFree: false
      rewriteThis: true
    normalArgs = _.isArray args
    if normalArgs
      args.map (x) -> insideEnv.markArgs x.text
    else
      insideEnv.registerVar (S args.text, args)
    body = expr[2..]
    last = expr[expr.length-1]
    [
      S '(function (_this) {', head
      indent
      newline
      S 'return function (', head
      if normalArgs then transformList args, env, argsState
      S ') {', head
      indent
      insideEnv
      unless normalArgs then [
        newline
        S args.text, args
        S ' = [].slice.call(arguments, 0)', head
        semicolon
      ]
      transformList body, insideEnv, insideState
      unindent
      newline
      S '}', head
      unindent
      newline
      S '})(', head
      S (if state.rewriteThis then '_this' else 'this'), head
      S ')', head
    ]

  'new': (expr, env, state) ->
    head = expr[0]
    construct = expr[1]
    options = expr[2..]
    insideState =
      position: 'inlineList'
      wantReturn: no
      bracketFree: false
      rewriteThis: state.rewriteThis
    before = [
      S 'new', head
      space
      S construct.text, construct
      S '(', head
      transformList options, env, insideState
      S ')', head
    ]

  '.': (expr, env, state) ->
    head = expr[0]
    dict = expr[1]
    insideState =
      position: 'inline'
      wantReturn: no
      bracketFree: false
      rewriteThis: state.rewriteThis
    key = expr[2]
    [
      transformExpr dict, env, insideState
      S '[', head
      transformExpr key, env, insideState
      S ']', head
    ]

  '?': (expr, env, state) ->
    head = expr[0]
    insideState =
      position: 'inline'
      wantReturn: no
      bracketFree: false
      rewriteThis: state.rewriteThis
    value = transformExpr expr[1], env, insideState
    if _.isArray expr[1]
      [
        value
        S ' != null', head
      ]
    else
      [
        S '(typeof ', head
        value
        S ' !== \'undefined\') && (', head
        value
        S ' !== null)', head
      ]

  '?=': (expr, env, state) ->
    head = expr[0]
    variable = expr[1]
    value = expr[2]
    insideState =
      position: 'inline'
      wantReturn: no
      bracketFree: false
      rewriteThis: state.rewriteThis
    unless variable.text.match(regVariable)?
      throw new Error "path can not be assgined ==#{variable.text}=="
    [
      S 'if (', head
      S variable.text, variable
      S ' == null) {', head
      indent
      newline
      S variable.text, variable
      space
      S '=', head
      space
      transformExpr value, env, insideState
      semicolon
      unindent
      newline
      S '}', head
    ]

  '++:': (expr, env, state) ->
    head = expr[0]
    insideState =
      position: 'inline'
      wantReturn: no
      bracketFree: false
      rewriteThis: state.rewriteThis
    expr[1..].map (x, index) ->
      [
        S (if index is 0 then '\'\' + ' else ' + '), head
        transformExpr x, env, insideState
      ]

  'while': (expr, env, state, pos) ->
    head = expr[0]
    cond = expr[1]
    body = expr[2..]
    condState =
      position: 'inline'
      wantReturn: no
      bracketFree: yes
      rewriteThis: state.rewriteThis
    insideState =
      position: 'statement'
      wantReturn: no
      bracketFree: false
      rewriteThis: state.rewriteThis
    [
      S 'while (', head
      transformExpr cond, env, condState
      S ') {', head
      indent
      transformList body, env, insideState
      unindent
      newline
      S '}', head
    ]

  'for': (expr, env, state) ->
    head = expr[0]
    cond = expr[1]
    body = expr[2..]
    refVar = env.makeRefN head
    lenVar = env.makeLenN head
    condState =
      position: 'inline'
      wantReturn: no
      bracketFree: false
      rewriteThis: state.rewriteThis
    insideState =
      position: 'statement'
      wantReturn: false
      bracketFree: false
      rewriteThis: state.rewriteThis
    unless _.isArray(cond) and (cond.length is 3)
      throw new Error 'cond should an array which leng is 3'
    variable = cond[0]
    key = cond[1]
    value = cond[2]
    env.registerVar (S key.text, key)
    env.registerVar (S value.text, value)
    [
      refVar
      S ' = ', head
      transformExpr variable, env, condState
      semicolon
      newline
      S 'for (', head
      S key.text, key
      S ' = 0, ', head
      lenVar
      S ' = ', head
      refVar
      S '.length; ', head
      S key.text, key
      S ' < ', head
      lenVar
      semicolon
      space
      S key.text, key
      S '++) {', head
      indent
      newline
      transformExpr value, env, condState
      S ' = ', head
      refVar
      S '[', head
      S key.text, key
      S ']', head
      semicolon
      transformList body, env, insideState
      unindent
      newline
      S '}', head
    ]

  'range': (expr, env, state) ->
    head = expr[0]
    unless expr.length is 3
      throw new Error 'range takes two arguments'
    insideState =
      position: 'inline'
      wantReturn: false
      bracketFree: false
      rewriteThis: state.rewriteThis
    a = transformExpr expr[1], env, insideState
    b = transformExpr expr[2], env, insideState
    [
      S '(function () {', head
      indent
      newline
      S 'var _i, _results;', head
      newline
      S '_results = [];', head
      newline
      S 'for (var _i = ', head
      a
      S '; ', head
      a
      S ' <= ', head
      b
      S ' ? _i <= ', head
      b
      S ' : _i >= ', head
      b
      S '; ', head
      a
      S ' <= ', head
      b
      S ' ? _i++ : _i--){ _results.push(_i); }', head
      newline
      S 'return _results;', head
      unindent
      newline
      S '})()', head
    ]

  'if': (expr, env, state, pos, outsideState) ->
    head = expr[0]
    cond = expr[1]
    trueExpr = expr[2]
    falseExpr = expr[3]
    if outsideState.position is 'statement'
      condState =
        position: 'inline'
        wantReturn: false
        bracketFree: true
        rewriteThis: state.rewriteThis
      insideState =
        position: 'inline'
        bracketFree: true
        wantReturn: state.wantReturn
        rewriteThis: state.rewriteThis
      [
        S 'if (', head
        transformExpr cond, env, condState
        S ') {', head
        indent
        transformExpr trueExpr, env, insideState
        unindent
        newline
        S '} else {', head
        indent
        if falseExpr?
        then transformExpr falseExpr, env, insideState
        unindent
        newline
        S '}', head
      ]
    else
      condState =
        position: 'inline'
        wantReturn: false
        bracketFree: false
        rewriteThis: state.rewriteThis
      [
        transformExpr cond, env, condState
        S '? ', head
        transformExpr trueExpr, env, condState
        S ' : ', head
        if falseExpr?
        then transformExpr falseExpr, env, condState
        else S 'undefined', head
      ]

  'do': (expr, env, state) ->
    state.position = 'statement'
    transformList expr[1..], env, state

  'try': (expr, env, state) ->
    head = expr[0]
    trueExpr = expr[1]
    error = expr[2]
    falseExpr = expr[3]
    errorState =
      position: 'inline'
      bracketFree: yes
      wantReturn: false
      rewriteThis: state.rewriteThis
    [
      S 'try {', head
      indent
      transformExpr trueExpr, env, errorState
      unindent
      newline
      S '} catch (', head
      if error?
      then transformExpr error, env, errorState
      else S '_error', head
      S ') {', head
      indent
      if falseExpr?
      then transformExpr falseExpr, env, errorState
      unindent
      newline
      S '}', head
    ]

  'switch': (expr, env, state, pos, outsideState) ->
    head = expr[0]
    target = expr[1]
    body = expr[2..]
    isInline = outsideState.position is 'inline'
    condState =
      position: 'inline'
      wantReturn: false
      bracketFree: true
      rewriteThis: state.rewriteThis
    insideState =
      position: 'statement'
      wantReturn: if isInline then yes else state.wantReturn
      bracketFree: false
      rewriteThis: state.rewriteThis
    pairs = body.map (pair) ->
      [
        newline
        if pair[0].text is 'else'
        then S 'default', head
        else [
          S 'case ', head
          transformExpr pair[0], env, condState
        ]
        S ':', head
        indent
        transformList pair[1..], env, insideState
        unless pair[0].text is 'else' then [
          newline,
          S 'break;', head
        ]
        unindent
      ]
    res = [
      S 'switch (', head
      transformExpr target, env, condState
      S ') {', head
      indent
      pairs
      unindent
      newline
      S '}', head
    ]
    return res unless isInline
    [
      S '(function () {', head
      indent
      newline
      res
      unindent
      newline
      S '})()', head
    ]

  'cond': (expr, env, state, pos, outsideState) ->
    head = expr[0]
    body = expr[1..]
    isInline = outsideState.position is 'inline'
    condState =
      position: 'inline'
      wantReturn: false
      bracketFree: true
      rewriteThis: state.rewriteThis
    insideState =
      position: 'statement'
      wantReturn: if isInline then yes else state.wantReturn
      bracketFree: false
      rewriteThis: state.rewriteThis
    pairs = body.map (pair) ->
      [
        newline
        if pair[0].text is 'else'
        then S 'default', head
        else [
          S 'case !(', head
          transformExpr pair[0], env, condState
          S ')', head
        ]
        S ':', head
        indent
        transformList pair[1..], env, insideState
        unindent
      ]
    res = [
      S 'switch (false) {', head
      indent
      pairs
      unindent
      newline
      S '}', head
    ]
    return res unless isInline
    [
      S '(function () {', head
      indent
      newline
      res
      unindent
      newline
      S '})()', head
    ]

  'throw': (expr, env, state) ->
    head = expr[0]
    body = expr[1]
    insideState =
      position: 'inline'
      wantReturn: no
      bracketFree: yes
      rewriteThis: state.rewriteThis
    [
      S 'throw ', head
      transformExpr body, env, insideState
    ]

  'return': (expr, env, state) ->
    head = expr[0]
    body = expr[1]
    insideState =
      position: 'inline'
      wantReturn: no
      bracketFree: yes
      rewriteThis: state.rewriteThis
    if body?
      [
        S 'return ', head
        transformExpr body, env, insideState
      ]
    else
      [
        S 'return', head
      ]

  'class': (expr, env, state) ->
    head = expr[0]
    name = expr[1]
    body = expr[2..]
    env.registerVar (S name.text, name)
    if _.isArray name
      throw new Error 'class name accepts token'
    nameState =
      position: 'inline'
      wantReturn: no
      bracketFree: yes
      rewriteThis: state.rewriteThis
    construct = null
    constructState =
      position: 'inline'
      wantReturn: no
      bracketFree: yes
      rewriteThis: false
      nameSegment: S name.text, name
    pairs = body.map (pair) ->
      if pair[0].text is ':constructor'
        construct = pair[1]
        return
      [
        newline
        newline
        S name.text, name
        S '.prototype[', name
        transformExpr pair[0], env, nameState
        S '] = ', name
        transformExpr pair[1], env, nameState
        semicolon
      ]
    [
      S name.text, name
      S ' = (function () {', head
      indent
      newline
      if construct?
        transformExpr construct, env, constructState
      else
        [
          S 'function ', head
          S name.text, name
          S '() {}', head
        ]
      pairs
      newline
      S 'return ', head
      S name.text, head
      semicolon
      unindent
      newline
      S '})()', head
    ]

  '!': (expr, env, state) ->
    head = expr[0]
    body = expr[1]
    insideState =
      position: 'inline'
      wantReturn: no
      bracketFree: false
      rewriteThis: state.rewriteThis
    [
      S '!', head
      transformExpr body, env, insideState
    ]

  'in': (expr, env, state) ->
    head = expr[0]
    body = expr[1..]
    insideState =
      position: 'inlineList'
      wantReturn: false
      bracketFree: false
      rewriteThis: state.rewriteThis
    [
      S "[].indexOf.call(", head
      transformList body, env, insideState
      S ") >= 0", head
    ]

  'of': (expr, env, state) ->
    head = expr[0]
    cond = expr[1]
    body = expr[2..]
    unless _.isArray cond
      throw new Error 'of accepts list of 3'
    variable = cond[0]
    key = cond[1]
    value = cond[2]
    if _.isArray key
      throw new Error "key in 'of' syntax uses token"
    if _.isArray value
      throw new Error "value in 'of' syntax uses token"
    condState =
      position: 'inline'
      wantReturn: false
      bracketFree: false
      rewriteThis: state.rewriteThis
    insideState =
      position: 'statement'
      wantReturn: false
      bracketFree: false
      rewriteThis: state.rewriteThis
    env.registerVar (S key.text, key)
    env.registerVar (S value.text, value)
    refVar = env.makeRefN head
    [
      refVar
      S ' = ', head
      transformExpr variable, env, condState
      semicolon
      newline
      S 'for (', head
      S key.text, key
      S ' in ', head
      refVar
      S ') {', head
      indent
      newline
      S value.text, value
      S ' = ', head
      refVar
      S '[', head
      S key.text, key
      S ']', head
      semicolon
      transformList body, env, insideState
      unindent
      newline
      S '}', head
    ]
  '...': (expr, env, state) ->
    head = expr[0]
    variable = expr[1]
    body = expr[2..]
    nameState =
      position: 'inline'
      wantReturn: false
      bracketFree: false
      rewriteThis: state.rewriteThis
    argsState =
      position: 'inlineList'
      wantReturn: false
      bracketFree: false
      rewriteThis: state.rewriteThis
    segmentVar = transformExpr variable, env, nameState
    segmentBody = body.map (pair) ->
      method = pair[0]
      unless method.text[0] is ':'
        throw new Error 'chain methods require string but : is misssing'
      args = pair[1..]
      [
        newline
        S '.', head
        S method.text[1..], method
        S '(', head
        transformList args, env, argsState
        S ')', head
      ]
    [
      segmentVar
      segmentBody
    ]
