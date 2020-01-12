
compiler = require './browser'
require './main.css'

setSource = (code) ->
  source = document.querySelector '#source'
  source.value = code

setCompiled = (code) ->
  compiled = document.querySelector '#compiled'
  compiled.value = code

req = new XMLHttpRequest
req.open 'GET', './examples/assign.cirru'
# req.open 'GET', 'http://repo/Memkits/pudica/source/utils/dispatcher.cirru'
req.send()
req.onload = ->
  code = req.responseText
  setSource code

  js = compiler.compile code
  setCompiled js

window.onload = ->
  source = document.querySelector '#source'
  source.oninput = (event) ->
    code = source.value
    try
      js = compiler.compile code
      setCompiled js
    catch error
      setCompiled error
