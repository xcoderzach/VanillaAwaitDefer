require("should")
{unnestName, await, awaitOne, serialAwait} = require("../await_defer")

database =
  "Zach": {id:1}
  "Eugene": {id:2}
  "Chad": {id:3}
  "Brian": {id:4}

# So lazy!
databaseById =
  1: {image:"zach.jpg", posts: 2}
  2: {image:"eugene.jpg", posts: 4}
  3: {image:"chad.jpg", posts: 3}
  4: {image:"brian.jpg", posts: 8}

getUserCredentials = (cb) ->
  #simulate async
  process.nextTick () ->
    cb(true, {name: "Zach Smith"})

getIdFromName = (name, cb) ->
  process.nextTick () ->
    cb(database[name].id)

getUserImageFromId = (id, cb) ->
  process.nextTick () ->
    cb(databaseById[id].image)

getUserPostCountFromId = (id, cb) ->
  process.nextTick () ->
    cb(databaseById[id].posts)
    cb(100)

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

describe "awaitOne", ->
  it "should call the second callback with arguments pass when it's done", (done) ->

    awaitOne (defer) ->

      getUserCredentials defer()

    , (loggedIn, credentials) ->

      loggedIn.should.equal(true)
      credentials.name.should.equal("Zach Smith")
      done()

describe "serialAwait", () ->
  it "should run one await after another, but run multiple serial awaits in parallel", (done) ->
    called = 0
    for name in ["Zach", "Chad", "Eugene", "Brian"]
      do (name) ->
        sawait = serialAwait()
        sawait (defer) ->
          getIdFromName(name, defer("id"))
        sawait ({id}, defer) ->
          getUserImageFromId id, defer("userImage")
          getUserPostCountFromId id, defer("postCount")
        , ({id, userImage, postCount}) ->

          id.should.equal database[name].id
          userImage.should.equal databaseById[id].image
          postCount.should.equal databaseById[id].posts

          called += 1
          if called == 4
            done()


describe "unnestName", ->
  it "should nest objects", ->
    unnestName({}, "thing[magic][stuff]", 34).should.eql({thing:{magic:{stuff:34}}})
  it "should nest arrays", ->
    object = unnestName({}, "thing[0][stuff]", "w00t")
    object = unnestName(object, "thing[1][stuff]", "w00t2")
    object.thing[0].stuff.should.equal "w00t"
    object.thing[1].stuff.should.equal "w00t2"
  it "shouldn't mess with unnested values", ->
    object = unnestName({}, "thing", "w00t")
    object.thing.should.equal "w00t"
