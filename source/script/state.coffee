
_ = require 'lodash'

class State
  constructor: (options) ->
    @useReturn = no
    @inline = no
    @decoration = no

  spawn: (options) ->
    child = new State
    child.useReturn = @useReturn
    child.inline = @inline
    child.decoration @decoration
    _.assign child, options
    child

module.exports = new State
