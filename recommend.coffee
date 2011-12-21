{serialAwait} = require("../await_defer")
class Recommender

  getRecommendations: (search_params, cb) ->

    await = serialAwait()

    # Do 2 things at once:
    #  - check if we have a logged in user, get their info
    #  - fire off distributed requests for search queries
    # ------------------------------------------------------------------------

    await (defer) ->
      @isLoggedIn defer "logged_in", "user_info"
      for interest in search_params.interests
        @getMetaInfo interest.text, defer interest.text

    #
    # Do more things at once:
    #   - get a taste profile for the user (only if logged in)
    #   - get taste profiles for each legit search interest
    # ------------------------------------------------------------------------

    await (results, defer) ->
      taste_profiles = {}
      @getUserTasteProfile user_info.id, defer user_taste_profile if logged_in
      for interest, meta of interest_meta
        @getTasteProfile meta.id, defer taste_profiles[meta.id] if meta
    

    #
    # Get the recommendations, combining all the taste profiles
    # ------------------------------------------------------------------------

    await (defer) -> @getRecsFromTasteProfiles taste_profiles, user_taste_profile, defer recommendations

    #
    # We have recs, but just [id, score] pairs. Let's:
    #   - look up info on each interest
    #   - save that this user got these recs (if logged in)
    # ------------------------------------------------------------------------
    #
    await (defer) ->
      for v,i in recommendations
        @getInfo v[0], defer full_recommendations[i]
      @rememberRecommendations user_info.id, recommendations, defer() if logged_in
    , () ->
    cb full_recommendations

  # --------------------------------------------------------------------------


  # --------------------------------------------------------------------------
  # Fake functions, for those who want to test getRecommendations()
  # I added some management of what's concurrent
  # --------------------------------------------------------------------------

  isLoggedIn: (cb) ->
    @_fakeRpc "logged_in", =>
      if Math.random() < 0.5
        cb true,
          id: "user_id_#{Math.random()}"
          age: Math.floor(18 + 30 * Math.random())
        
      else
        cb false, null

  getRecsFromTasteProfiles: (tp, utp, cb) ->
    @_fakeRpc "get_recs", =>
      res = []
      for i in [0..10]
        res.push ["interest_id_#{Math.random()}", Math.random()]
      cb res

  getMetaInfo: (search_str, cb) ->
    @_fakeRpc "get_meta", ->
      cb id: "interest_id_#{Math.random()}" 

  getUserTasteProfile: (uid, cb) -> 
    @_fakeRpc "get_user_taste", ->
      cb Math.random()

  getTasteProfile: (uid, cb) -> 
    @_fakeRpc "get_taste", ->
      cb Math.random()

  getInfo: (rec_id, cb) ->
    @_fakeRpc "get_info", ->
      cb
        title: "Bangin'"
        avg_age: Math.floor(18 + 30 * Math.random())
        id: rec_id

  rememberRecommendations: (id, recommendations, cb) ->
    @_fakeRpc "rememberRecommendations", cb

  # --------------------------------------------------------------------------

  _fakeRpc: (name, cb) ->
    @_openRpcCount = {} if not @_openRpcCount
    @_openRpcCount[name] = 0 if not @_openRpcCount[name]
    @_openRpcCount[name]++
    @_printFakeRpcData()
    setTimeout((()=>
      @_openRpcCount[name]--
      @_printFakeRpcData()
      cb()),Math.random()*1000)

  _printFakeRpcData: ->
    console.log "open remote calls: " + ("#{k} (#{v})" for k,v of @_openRpcCount).join(" ")


R = new Recommender()

search_params =
  interests: [ { text: "football", opinion: 1.23 }, { text: "basketball", opinion: 13.23 } ]

start_time = Date.now()

R.getRecommendations search_params, (res) ->
  console.log "-------------"
  console.log "Done. Got #{res.length} results in #{Date.now() - start_time}ms"
