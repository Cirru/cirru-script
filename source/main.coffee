
compiler = require './script/compiler'

setSource = (code) ->
  source = document.querySelector '#source'
  source.value = code

setCompiled = (code) ->
  compiled = document.querySelector '#compiled'
  compiled.value = code

req = new XMLHttpRequest
req.open 'GET', './cirru/lambda.cirru'
req.send()
req.onload = ->
  code = req.responseText
  setSource code

  res = compiler.compile code
  setCompiled res.js
