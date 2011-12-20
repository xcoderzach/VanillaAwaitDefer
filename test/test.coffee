require("should")
await = require("../await_defer")

getUserCredentials = (cb) ->
  #simulate async
  process.nextTick () ->
    cb(true, {name: "Zach Smith"})

describe "await defer", ->
  it "should set values from defer calls", (done) ->
    await (defer) ->

      getUserCredentials defer("loggedIn", "credentials")

    , ({loggedIn, credentials}) ->

      loggedIn.should.equal(true)
      credentials.name.should.equal("Zach Smith")

      done()
  it "should call the second callback, even if defer isn't called", (done) ->
    await (defer) ->
      getUserCredentials ->
    , done

  it "should allow for multiple defer calls", (done) ->
    await (defer) ->
      # Get user credentials IN PARALLEL! (this is a nonsensical example, but it demonstrates paralellism
      getUserCredentials defer("userOneLoggedIn", "userOneCredentials")
      getUserCredentials defer("userTwoLoggedIn", "userTwoCredentials")

    , ({userOneLoggedIn, userTwoLoggedIn, userOneCredentials, userTwoCredentials}) ->

      userOneLoggedIn.should.equal(true)
      userOneCredentials.name.should.equal("Zach Smith")

      userTwoLoggedIn.should.equal(true)
      userTwoCredentials.name.should.equal("Zach Smith")

      done()
