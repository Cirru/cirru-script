
exports.expand = expand = (expr, env) ->
  if expr instanceof Array
    func = expr[0]
    macro expr, env
  else
    literal expr

literal = (content) ->
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

  switch
    when func is 'set'
      key = params[0]
      value = expand params[1]
      if key in env.vars then js = "#{key}=#{value}"
      else js = "var #{key}=#{value}"
      env.add key
      return makeRet js, env

    when func is 'number'
      value = params[0]
      js = "#{value}"
      return makeRet js, env