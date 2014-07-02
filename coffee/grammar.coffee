
exports.expand = expand = (expr, env) ->
  if expr instanceof Array
    func = expr[0]
    macro expr, env
  else
    literal expr

literal = (content) ->
  if content is '#t'
    return 'true'
  if content is '#f'
    return 'false'

  guessNumber = Number content
  if isNaN guessNumber
    return "'#{content}'"
  else
    return content

makeRet = (code, env) ->
  if env.expr then "(#{code})"
  else "#{code};"

# grammar rule that was defined

macro = (expr, env) ->
  func = expr[0]
  params = expr[1..]

  if func is 'set'
    key = params[0]
    scope = env.spawn expr: yes
    value = expand params[1], scope
    if key in env.vars then js = "#{key}=#{value}"
    else js = "var #{key}=#{value}"
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

  if func is 'string'
    str = params[0]
    return makeRet "\"#{str}\"", env

  if func is 'sentence'
    str = params.join(' ')
    return makeRet "\"#{str}\"", env

  if func is 'array'
    scope = env.spawn expr: yes
    items = params.map (param) ->
      expand param, scope
    js = "[#{items.join(',')}]"
    return makeRet js, env