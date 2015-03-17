
compiler = require './script/compiler'

setSource = (code) ->
  source = document.querySelector '#source'
  source.value = code

setCompiled = (code) ->
  compiled = document.querySelector '#compiled'
  compiled.value = code

req = new XMLHttpRequest
req.open 'GET', './cirru/class.cirru'
# req.open 'GET', 'http://repo/Memkits/pudica/source/utils/dispatcher.cirru'
req.send()
req.onload = ->
  code = req.responseText
  setSource code

  res = compiler.compile code, {relativePath: 'demo'}
  setCompiled res.js
  setCompiled res.js
  window.c = "#{res.js}\n//# sourceURL=demo.js"

window.onload = ->
  source = document.querySelector '#source'
  source.oninput = (event) ->
    code = source.value
    try
      res = compiler.compile code, {relativePath: 'demo'}
      setCompiled res.js
    catch error
      setCompiled error
