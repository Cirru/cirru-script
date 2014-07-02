
exports.expand = expand = (expr, env) ->
  if expr instanceof Array
    func = expr[0]
    macro expr, env
  else
    literal expr, env

literal = (content, env) ->
  if content is '#t'
    return 'true'
  if content is '#f'
    return 'false'

  guessNumber = Number content
  if content in env.vars or (not (isNaN guessNumber))
    return content
  else
    throw new Error "'#{content}' is not defined"

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

  if func[0] is '.'
    scope = env.spawn expr: yes
    name = params[0]
    if name instanceof Array
      name = expand name, scope
    args = params[1..].map (expr) ->
      expand expr, scope
    js = "(#{name})#{func}(#{args.join(', ')})"
    return makeRet js, env