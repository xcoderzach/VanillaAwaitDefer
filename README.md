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

#a slightly shorter syntax, for the case where you only want to wait for one thing
awaitOne (d) -> getUserCredentials d(), (loggedIn, credentials) ->
  # use the variables here
 
```

## Run the tests
    npm install mocha should
    mocha test/test.coffee

## LICENSE
  MIT (see LICENSE.txt)

