
module.exports = class Env
  constructor: (parent) ->
    @parent = parent
    @varables = []
    @args = []
    if @parent?
      @level = @parent.level + 1
      @lenN = @parent.lenN + 1
      @refN = @parent.refN + 1
    else
      @level = 0
      @lenN = 0
      @refN = 0

  type: 'declaration'

  makeLenN: (node) ->
    x = type: 'segment', name: "_len#{@lenN}", x: node.x, y: node.y
    @lenN += 1
    @varables.push x
    x

  makeRefN: (node) ->
    x = type: 'segment', name: "_ref#{@refN}", x: node.x, y: node.y
    @refN += 1
    @varables.push x
    x

  checkVar: (x) ->
    for item in @varables
      if item.name is x.name
        return true
    if @parent?
      @parent.checkVar x
    else
      false

  registerVar: (x) ->
    unless x.name.match(/^[\$_\w][\$_\w\d]*$/)
      return
    exists = @checkVar(x)
    unless exists
      @varables.push x

  markArgs: (name) ->
    @args.push name

  getSegments: ->
    varables = @varables.filter (x) =>
      not (x.name in @args)
    if varables.length is 0
      return []
    collections = [
      type: 'control', name: 'newline'
    ,
      type: 'control', name: 'var'
    ,
      type: 'control', name: 'space'
    ]
    for x, index in varables
      if index > 0
        collections.push type: 'control', name: 'comma'
        collections.push type: 'control', name: 'space'
      collections.push x
    collections.push type: 'control', name: 'semicolon'
    collections
