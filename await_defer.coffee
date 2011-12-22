module.exports.unnestName = unnestName = (object, name, value) ->
  baseName = name.match(/^([a-z0-9\-_]+)(?:\[|$)/i)[1]
  nestings = name.match(/(\[([a-z0-9]*)\])/gi) || []
  top = object
  nestings.unshift "[" + baseName + "]"
  for i in [0...nestings.length]
    key = nestings[i].slice(1, -1)
    if key.match(/^[0-9]+$/)
      key = parseInt(key)
    # empty array brackets like things[] should push to the end of the array
    else if key.match(/^$/) && Array.isArray(top)
      key = top.length
    if typeof top[key] != "object"
      if nestings[i+1]? && nestings[i+1].slice(1, -1).match(/^[0-9]*$/)
        top[key] = []
      else
        top[key] = {}
    # set the value to the last key
    if(i == nestings.length - 1)
      top[key] = value
    else
      top = top[key]
  return object

module.exports.await = await = (cbBefore, cbAfter) ->
  defersLeft = 0
  # keep track of total defers, in case one gets called syncronously
  # before we reach the end
  defersTotal = 0
  deferedArguments = {}
  setterOperations = []
  
  defer = () ->
    #use the total in case one was called and then immediatly returned
    operationNumber = defersTotal
    defersLeft += 1
    defersTotal += 1
    argNames = arguments

    return () ->
      defersLeft -= 1
      argValues = arguments
      # we should wait to set variables until we're about to call 
      # cbAfter, otherwise the order is random based on time
      # for callbacks to return
      setterOperations[operationNumber] = () ->
        for i in [0...argNames.length]
          deferedArguments = unnestName(deferedArguments, argNames[i], argValues[i])

      if defersLeft == 0
        for i in [0...setterOperations.length]
          setterOperations[i]()
        cbAfter(deferedArguments)
 
  cbBefore(defer)
  # In case no defer methods were called inside our first callback
  if defersTotal == 0
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
