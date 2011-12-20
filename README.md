# Vanilla Await Defer

  Here's my attempt at implementing the await and defer features, without 
modifying the language itself.

## Examples


```coffeescript
await (defer) ->
  getUserCredentials defer("loggedIn", "credentials")

, ({loggedIn, credentials}) ->
  # use the variables here

await (defer) ->
  # Get user credentials IN PARALLEL! (this is a nonsensical example, but it demonstrates paralellism
  getUserCredentials defer("userOneLoggedIn", "userOneCredentials")
  getUserCredentials defer("userTwoLoggedIn", "userTwoCredentials")

, ({userOneLoggedIn, userTwoLoggedIn, userOneCredentials, userTwoCredentials}) ->
  # We have all of the things we set!
```
### awaitOne

  a slightly shorter syntax, for the case where you only want to wait for one
  thing

```coffeescript
awaitOne (d) -> getUserCredentials d(), (loggedIn, credentials) ->
  # use the variables here
```
 

#Serial Await
  In order to prevent indentation creep, you can use sawait, which will not
start a second await until the first has finished
 
  It returns an await function that will wait for the previously called await
function before it goes await = sawait() for i in [0...10]
and will take the result of the previous await as the first argument 

```coffeescript
for name in ["Zach", "Eugene", "Chad", "Brian"]
  sawait = serialAwait() 
  sawait (defer) -> 
    getIdFromName name defer("id")
  sawait ({id}, (defer) ->
    getUserImageFromId id, defer "userImage"
    getUserPostCountFromId id, defer "postCount"
  , ({userImage, postCount, id}) ->
    console.log(name + "with id " + id + " looks like " + 
                userImage + "and has posted" + postCount + "times")
``` 

## Run the tests
    npm install mocha should
    mocha test/test.coffee

## LICENSE
  MIT (see LICENSE.txt)

