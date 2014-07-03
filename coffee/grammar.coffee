
exports.expand = expand = (expr, env) ->
  if expr instanceof Array
    func = expr[0]
    js = macro expr, env
    env.last = func
    js
  else
    env.last = null
    literal expr, env

literal = (content, env) ->
  if content is '#t'
    return 'true'
  if content is '#f'
    return 'false'
  if content in ['null', 'undefined']
    return 'null'

  guessNumber = Number content
  if content in env.vars or (not (isNaN guessNumber))
    return content
  else
    throw new Error "'#{content}' is not defined"

makeRet = (code, env) ->
  if env.expr then "(#{code})"
  else
    if code.match /\}$/ then code
    else "#{code};"

# grammar rule that was defined

macro = (expr, env) ->
  func = expr[0]
  params = expr[1..]

  if func is 'set'
    key = params[0]
    scope = env.spawn expr: yes
    value = expand params[1], scope
    if key in env.vars then js = "#{key} = #{value}"
    else js = "var #{key} = #{value}"
    env.add key
    return makeRet js, env

  if func is 'number'
    value = params[0]
    js = "#{value}"
    return makeRet js, env

  if func is '--'
    return ''

  if func is 'number'
    js = params[0]
    return makeRet js, env

  if func in ['string', '=']
    str = params[0]
    return makeRet "\"#{str}\"", env

  if func is 'regex'
    str = params[0]
    return makeRet "/#{str}/", env

  if func is 'sentence'
    str = params.join(' ')
    return makeRet "\"#{str}\"", env

  if func is 'array'
    scope = env.spawn expr: yes
    items = params.map (param) ->
      expand param, scope
    js = "[#{items.join(', ')}]"
    return makeRet js, env

  if func is 'object'
    pairs = []
    scope = env.spawn expr: yes
    for pair in params
      if pair instanceof Array
        key = pair[0]
        value = expand pair[1], scope
        pairs.push "#{key}: #{value}"
      else
        pairs.push "#{pair}: #{pair}"
    js = "{#{pairs.join(', ')}}"
    return makeRet js, env

  if func.match /^\d+$/
    scope = env.spawn expr: yes
    list = expand params[0], scope
    js = "#{list}[#{func}]"
    return makeRet js, env

  if func.match /^-\d+$/
    scope = env.spawn expr: yes
    list = expand params[0], scope
    js = "#{list}[#{list}.length - #{func}]"
    return makeRet js, env

  if func.match /^\:\S+$/
    scope = env.spawn expr: yes
    name = params[0]
    if name instanceof Array
      name = expand name, scope
    js = "#{name}.#{func[1..]}"
    return makeRet js, env

  if func is '.'
    scope = env.spawn expr: yes
    name = params[0]
    if name instanceof Array
      name = expand name, scope
    chains = params[1..]
    .map (item) ->
      method = item[0]
      if method[0] is '.'
        args = item[1..]
        .map (arg) -> expand arg, scope
        .join(', ')
        return "#{method}(#{args})"
      else if method[0] is ':'
        ".#{method[1..]}"
    .join('')
    js = "#{name}#{chains}"
    return makeRet js, env

  if func[0] is '.'
    scope = env.spawn expr: yes
    name = params[0]
    if name instanceof Array
      name = expand name, scope
    args = params[1..].map (expr) ->
      expand expr, scope
    js = "(#{name})#{func}(#{args.join(', ')})"
    return makeRet js, env

  if func[0..1] is '=.'
    scope = env.spawn expr: yes
    name = params[0]
    if name instanceof Array
      name = expand name, expand
    value = expand params[1], scope
    js = "(#{name})#{func[1..]} = #{value}"
    return makeRet js, env

  if func is 'new'
    scope = env.spawn expr: yes
    name = params[0]
    args = params[1..].map (expr) ->
      expand expr, scope
    js = "new #{name}(#{args.join(', ')})"
    return makeRet js, env

  if func is '\\'
    scope = env.spawn expr: yes
    if params[0] instanceof Array
      args = params[0]
    else
      args = [params[0]]
    bodyScope = env.spawn expr: no
    bodyScope.vars.push args...
    body = params[1..]
    .map (expr, index) ->
      if (index + 2) is params.length
        subScope = bodyScope.spawn expr: yes
        retExpr = expand expr, subScope
        "return #{retExpr};"
      else
        expand expr, bodyScope
    .join('\n')

    js = "(function(#{args.join(', ')}){\n#{body}\n})"
    return makeRet js, env

  if func in ['+', '-', '*', '/', '%', '&&', '||']
    scope = env.spawn expr: yes
    js = params
    .map (expr) -> expand expr, scope
    .join(" #{func} ")
    return makeRet js, env

  if func in ['+=', '-=', '*=', '/=', '%=']
    scope = env.spawn expr: yes
    value = expand params[0], scope
    delta = expand params[1], scope
    js = "#{value} += #{delta}"
    return makeRet js, env

  if func is 'not'
    scope = env.spawn expr: yes
    value = expand params[0], scope
    js = "! #{value}"
    return makeRet js, env

  if func is '==' then func = '==='
  if func in ['===', '!=', '>', '<', '>=', '<=']
    pairs = []
    scope = env.spawn expr: yes
    args = params.map (expr) -> expand expr, scope
    for i in [0...(args.length-1)]
      j = i + 1
      a = args[i]
      b = args[j]
      pairs.push "(#{a} #{func} #{b})"
    js = pairs.join(' && ')
    return makeRet js, env

  if func is 'if'
    scope = env.spawn expr: yes
    cond = expand params[0], scope
    bodyScope = env.spawn()
    if bodyScope.expr
      cons = expand params[0], bodyScope
      alte = expand params[1], bodyScope
      js = "((#{cond}) ? #{cons} : #{alte})"
      return js
    else
      lines = params[1..]
      .map (expr) -> expand expr, bodyScope
      .join('\n')
      js = "if (#{cond}) {\n#{lines}\n}"
      return js

  if func is 'else'
    unless env.last in ['if', 'elseif']
      console.log 'stopped at:', expr
      throw new Error 'unexpected else'
    scope = env.spawn()
    lines = params
    .map (expr) -> expand expr, scope
    .join('\n')
    js = "else {\n#{lines}\n}"
    return makeRet js, env

  if func is 'elseif'
    unless env.last in ['if', 'elseif']
      console.log 'stopped at:', expr
      throw new Error 'unexpected elseif'
    scope = env.spawn expr: yes
    cond = expand params[0], scope
    bodyScope = env.spawn()
    lines = params[1..]
    .map (expr) -> expand expr, bodyScope
    .join('\n')
    js = "else if (#{cond}) {\n#{lines}\n}"
    return js

  if func in ['break', 'continue']
    return "#{func};"

  console.log 'stopped at:', expr
  throw new Error "no macro is found"