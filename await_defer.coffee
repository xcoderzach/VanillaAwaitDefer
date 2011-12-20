module.exports.await = await = (cbBefore, cbAfter) ->
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

module.exports.serialAwait = () ->
  awaits = []
  first = true
  deferedArguments = {}
  sawait = (cbBefore, cbAfter) ->
    awaits.push
      before: (defer) ->
        #the first callback won't have a hash of arguments
        if first
          first = false
          cbBefore(defer)
        else
          cbBefore(deferedArguments, defer)
      after: (args) ->
        #first copy all of the new values onto the old ones
        deferedArguments[key] = val for key, val of args
        # if this is the last await on the chain
        next = awaits.shift()
        if(next)
          { before, after } = next
          #call teh next one in the line
          await(before, after)
        else
          cbAfter(deferedArguments)
    if first
      {before, after} = awaits.shift()
      await(before, after)
          
  return sawait
