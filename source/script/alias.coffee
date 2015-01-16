
table =
  'is': '=='
  '=': 'set'
  'and': '&&'
  'or': '||'
  '\\': 'lambda'

exports.rewrite = (token) ->
  newName = table[token.text]
  if newName?
    token.text = newName
