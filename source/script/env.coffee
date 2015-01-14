
module.exports = class Env
  constructor: (parent) ->
    @parent = parent
    @varables = []
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
        return false
    if @parent?
      @parent.checkVar x
    else
      false

  registerVar: (x) ->
    exists = @checkVar(x)
    unless exists
      @varables.push x
