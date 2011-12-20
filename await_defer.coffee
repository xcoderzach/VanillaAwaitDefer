module.exports.await = (cbBefore, cbAfter) ->
  defers = 0
  deferedArguments = {}
  
  defer = () ->
    defers += 1
    argNames = arguments
    return () ->
      for i in [0...argNames.length]
        deferedArguments[argNames[i]] = arguments[i]
      defers -= 1
      if defers == 0
        cbAfter(deferedArguments)
 
  cbBefore(defer)
  # In case no defer methods were called inside our first callback
  if defers == 0
    cbAfter()

module.exports.awaitOne = (cbBefore, cbAfter) ->
  defer = () ->
    return ->
      cbAfter.apply(null, arguments)

  cbBefore(defer)
