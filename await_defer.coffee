module.exports.unnestName = unnestName = (object, name, value) ->
  baseName = name.match(/^([a-z0-9\-_]+)(?:\[|$)/i)[1]
  nestings = name.match(/(\[([a-z0-9]+)\])/gi) || []
  top = object
  nestings.unshift "[" + baseName + "]"
  for i in [0...nestings.length]
    key = nestings[i].slice(1, -1)
    if key.match(/^[0-9]+$/)
      key = parseInt(key)
    if typeof top[key] != "object"
      if nestings[i+1]? && nestings[i+1].slice(1, -1).match(/^[0-9]+$/)
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
  defers = 0
  deferedArguments = {}
  
  defer = () ->
    defers += 1
    argNames = arguments
    return () ->
      for i in [0...argNames.length]
        deferedArguments = unnestName(deferedArguments, argNames[i], arguments[i])
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
