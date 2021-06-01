import Access "../library/Access";
import Array "mo:base/Array";
import Hash "mo:base/Hash";
import Base "../library/Base";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import HashMap "mo:base/HashMap";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import List "mo:base/List";
import Nat "mo:base/Nat";
import Option "mo:base/Option";
import P "mo:base/Prelude";
import Param "../library/Param";
import Prelude "mo:base/Prelude";
import Principal "mo:base/Principal";
import Rel "../library/Rel";
import RelObj "../library/RelObj";
import State "../library/State";
import Text "mo:base/Text";
import Time "mo:base/Time";
import TrieMap "mo:base/TrieMap";
import Types "../library/Types";

shared ({caller = initPrincipal}) actor class CandidSpaces () {

  var state = State.empty({ admin = initPrincipal });

  public type UserId = Types.UserId;
  public type ProfileInfo = Types.ProfileInfo;

  public type ViewId = Types.ViewId;
  public type ViewPos = Types.View.Position;
  public type Image = Types.View.Image;

  public type CandidValue = Types.Candid.Value.Value;
  public type SpacePath = Types.Space.Path.Path;
  public type ViewTargets = Types.View.Target.Targets;
  public type ViewGathering = Types.View.Gathering;

  /// log the given event kind, with a unique ID and current time
  func logEvent(ek : State.Event.EventKind) {
    state.eventLog.add({
                         id = state.eventCount ;
                         time = timeNow_() ;
                         kind = ek
                       });
    state.eventCount += 1;
  };

  // responsible for adding metadata from the user to the state.
  // a null principal means that the username has no valid callers (yet), and the admin
  // must relate one or more principals to it.
  func createProfile_(userName_ : Text, p: ?Principal) : ?() {
    switch (state.profiles.get(userName_)) {
      case (?_) { /* error -- ID already taken. */ null };
      case null { /* ok, not taken yet. */
        let now = timeNow_();
        state.profiles.put(userName_, {
            userName = userName_ ;
            createdAt = now ;
        });
        logEvent(#createProfile({userName=userName_}));
        state.access.userRole.put(userName_, #user);
        switch p {
          case null { }; // no related principals, yet.
          case (?p) { state.access.userPrincipal.put(userName_, p); }
        };
        // success
        ?()
      };
    }
  };

  func accessCheck(caller : Principal, action : Types.UserAction, target : Types.ActionTarget) : ?() {
    state.access.check(timeNow_(), caller, action, target)
  };

  public shared(msg) func createProfile(userName : Text) : async ?ProfileInfo {
    do ? {
      accessCheck(msg.caller, #create, #user userName)!;
      createProfile_(userName, ?msg.caller)!;
      // return the full profile info
      getProfileInfo_(?userName, userName)! // self-view
    }
  };

  var timeMode : {#ic ; #script} =
    switch (Param.timeMode) {
     case (#ic) #ic;
     case (#script _) #script
    };

  var scriptTime : Int = 0;

  func timeNow_() : Int {
    switch timeMode {
      case (#ic) { Time.now() };
      case (#script) { scriptTime };
    }
  };

  public shared(msg) func scriptTimeTick() : async ?() {
    do ? {
      accessCheck(msg.caller, #admin, #all)!;
      assert (timeMode == #script);
      scriptTime := scriptTime + 1;
    }
  };

  func reset_( mode : { #ic ; #script : Int } ) {
    setTimeMode_(mode);
    state := State.empty({ admin = state.access.admin });
  };

  public shared(msg) func reset( mode : { #ic ; #script : Int } ) : async ?() {
    do ? {
      accessCheck(msg.caller, #admin, #all)!;
      reset_(mode)
    }
  };

  func setTimeMode_( mode : { #ic ; #script : Int } ) {
    switch mode {
      case (#ic) { timeMode := #ic };
      case (#script st) { timeMode := #script ; scriptTime := st };
    }
  };

  public shared(msg) func setTimeMode( mode : { #ic ; #script : Int } ) : async ?() {
    do ? {
      accessCheck(msg.caller, #admin, #all)!;
      setTimeMode_(mode)
    }
  };

  func getProfileInfo_(_viewer : ?UserId, target : UserId) : ?ProfileInfo {
    do ? {
      let profile = state.profiles.get(target)!;
      {
        userName = profile.userName ;
      }
    }
  };

  public query(msg) func getProfileInfo(viewer : ?UserId, userId : UserId) : async ?ProfileInfo {
    do ? {
      switch viewer {
        case null { };
        case (?v) {
               accessCheck(msg.caller, #update, #user v)!;
             };
      };
      accessCheck(msg.caller, #view, #user userId)!;
      getProfileInfo_(viewer, userId)!
    }
  };

  /// Put candid data into the space identified by the path.
  public shared(msg) func put(user_ : UserId, path_ : SpacePath, values_ : [ CandidValue ]) : async ?() {
    do ? {
      accessCheck(msg.caller, #update, #user user_)!;
      // to do --
      // access control for spaces,
      //   based on whitelists for viewers and updaters of private spaces,
      //   and just updater whitelists of public spaces.
      //accessCheck(msg.caller, #update, #space path_)!;
      logEvent(#put({user=user_; path=path_; values=values_}));
      let space = switch (state.spaces.get(path_)) {
        case null {
               // space does not exist; create it now.
               let space = {
                 createUser = user_;
                 createTime = timeNow_();
                 puts = State.Space.Puts.empty();
               };
               state.spaces.put(path_, space);
               space
        };
        case (?space) { space };
      };
      space.puts.add(
        {
          // invariant -- to do -- common time between event log and space data.
          time = timeNow_(); // to do -- use / assert same time as logEvent above
          user = user_;
          values = values_
        });
    }
  };


  /// A view is an immutable representation of a gathering of paths' data.
  ///
  /// Create a (temporary) view of the given paths,
  /// associated with the given user,
  /// gathered in the given way,
  /// with a given time to life (ttl).
  ///
  /// Views are inexpensive to create and are immutable once created;
  /// to "update a view", re-create it with the same parameters, later.
  ///
  public func createView(
    user_ : UserId,
    targets_ : ViewTargets,
    gathering_ : ViewGathering,
    ttl_ : ?Nat)
    : async ?Types.View.CreateViewResponse
  {
    do ? {
      switch gathering_ {
        case (#sequence) { };
        case _ { assert false ; /* to do -- handle other gatherings. */ }       };
      let spaces_ = Buffer.Buffer<State.Space.Space>(0);
      for (target in targets_.vals()) {
        switch target {
          case (#space(path)) {
            spaces_.add(state.spaces.get(path)!)
          };
          case (#view(viewId)) {
            loop { assert false };
          };
        }
      };
      let createEvent_ =
        {
          createUser = user_;
          createTime = timeNow_();
          targets = targets_;
          gathering = gathering_ ;
          ttl = ttl_
        };
      logEvent(#createView(createEvent_));
      let id = do {
        let id = state.viewCount;
        state.viewCount += 1;
        "view-" # Int.toText(id)
      };
      let spacesArray =
      state.views.put(
        id,
        {
          createEvent = createEvent_;
          spaces = spaces_.toArray() // to do -- get immutable reps
        });
      { viewId = id;
        putCount = {
          total = 666;  // to do
          target = [666]; // to do
        } }
    }
  };


  /// Get a full image (entire view) of gathered puts.
  /// May fail to complete if the view is too large;
  /// For "too large" views, use `getSubImage` multiple times, with tuning.
  public query(msg) func getFullImage(
    viewer : ?UserId,
    viewId : ViewId) : async ?Image {
    loop { assert false }
  };

  /// Get a sub-image of gathered puts.
  public query(msg) func getSubImage(
    viewer : ?UserId,
    viewId : ViewId,
    pos : ViewPos,
    size : Nat) : async ?Image {
    loop { assert false }
  };

}
