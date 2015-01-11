
parser = require 'cirru-parser'

setSource = (code) ->
  source = document.querySelector '#source'
  source.value = code

setCompiled = (code) ->
  compiled = document.querySelector '#compiled'
  compiled.value = code

req = new XMLHttpRequest
req.open 'GET', './cirru/assign.cirru'
req.send()
req.onload = ->
  code = req.responseText
  setSource code
  ast = parser.parse code
  demo = JSON.stringify ast, null, 2
  setCompiled demo
