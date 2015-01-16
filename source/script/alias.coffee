
table =
  'is': '=='
  'and': '&&'
  'or': '||'
  '\\': 'lambda'

exports.rewrite = (token) ->
  newName = table[token.text]
  if newName?
    token.text = newName
