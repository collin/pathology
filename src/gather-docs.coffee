args = phantom.args
if args.length < 1 || args.length > 2
  console.log("Usage: " + phantom.scriptName + " <URL> <timeout>")
  phantom.exit(1)

page = require('webpage').create()
page.onConsoleMessage = (msg) ->
  console.log(msg)

page.open args[0], (status) ->
  if status isnt 'success'
    console.error("Unable to access network");
    phantom.exit(1)
  else
    phantom.exit(1)

