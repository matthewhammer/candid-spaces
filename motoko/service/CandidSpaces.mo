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
import Sequence "mo:sequence/Sequence";

shared ({caller = initPrincipal}) actor class CandidSpaces () {

  var state = State.empty({ admin = initPrincipal });

  /// Stable memory-based event log
  stable var eventLog_20210616_2042 : EventLog = Sequence.empty();

  /// Sequence for stable memory-based event log
  public type Sequence<X> = Sequence.Sequence<X>;

  /// Type for stable memory-based event log
  public type Event = State.Event.Event;
  public type EventLog = Sequence<Event>;

  public type UserId = Types.UserId;
  public type ProfileInfo = Types.ProfileInfo;

  public type ViewId = Types.ViewId;
  public type ViewPos = Types.View.Position;
  public type Image = Types.View.Image;

  public type CandidValue = Types.Candid.Value.Value;
  public type SpacePath = Types.Space.Path.Path;
  public type ViewTargets = Types.View.Target.Targets;
  public type ViewGathering = Types.View.Gathering;

  let append = Sequence.defaultAppend();

  /// log the given event kind, with a unique ID and current time
  func logEvent(ek : State.Event.EventKind) {
    let eventCount = Sequence.size(eventLog_20210616_2042);
    let e = {
      id = eventCount ;
      time = timeNow_() ;
      kind = ek
    };

    /// Stable memory log (full history).
    eventLog_20210616_2042 :=
      append<Event>(eventLog_20210616_2042, Sequence.make(e));

    /// Flexible memory log (history since last upgrade).
    state.eventLog.add(e);
  };

  /// Variation where event kind requires knowing the ID of the event.
  func logEvent_(ek_ : Nat -> State.Event.EventKind) {
    let eventCount = Sequence.size(eventLog_20210616_2042);
    logEvent(ek_(eventCount))
  };

  // responsible for adding metadata from the user to the state.
  // a null principal means that the username has no valid callers (yet), and the admin
  // must relate one or more principals to it.
  func createProfile_(caller_ : Principal, userName_ : Text) : ?() {
    switch (state.profiles.get(userName_)) {
      case (?_) { /* error -- ID already taken. */ null };
      case null { /* ok, not taken yet. */
        let now = timeNow_();
        state.profiles.put(userName_, {
            userName = userName_ ;
            createdAt = now ;
        });
        logEvent(#createProfile({userName=userName_; caller = caller_}));
        state.access.userRole.put(userName_, #user);
        state.access.userPrincipal.put(userName_, caller_);
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
      createProfile_(msg.caller, userName)!;
      // return the full profile info
      getProfileInfo_(?userName, userName)! // self-view
    }
  };

  func timeNow_() : Int {
    Time.now()
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
  public shared(msg) func putQuick(user_ : UserId, path_ : SpacePath, values_ : [ CandidValue ]) {
    ignore put_(msg.caller, user_, path_, values_);
  };

  /// Put candid data into the space identified by the path.
  public shared(msg) func put(user_ : UserId, path_ : SpacePath, values_ : [ CandidValue ]) : async ?Types.PutId {
    put_(msg.caller, user_, path_, values_);
  };

  /// Put candid data into the space identified by the path.
  func put_(caller_ : Principal, user_ : UserId, path_ : SpacePath, values_ : [ CandidValue ]) : ?Types.PutId {
    do ? {
      // to do --
      // access control for spaces,
      //   based on whitelists for viewers and updaters of private spaces,
      //   and just updater whitelists of public spaces.
      //
      //accessCheck(msg.caaller, #update, #user user_)!;
      //accessCheck(msg.calleer, #update, #space path_)!;
      var putId : ?Nat = null;
      logEvent_(
        func (id_ : Nat) : State.Event.EventKind {
          putId := ?id_;
          #put({ id = id_;
                 caller = caller_;
                 user = user_;
                 path = path_;
                 values = values_})
        }
      );
      let space = switch (state.spaces.get(path_)) {
        case null {
               // space does not exist; create it now.
               let space = {
                 createCaller = caller_;
                 createUser = user_;
                 createTime = timeNow_();
                 path = path_ ;
                 puts = State.Space.Puts.empty();
               };
               state.spaces.put(path_, space);
               space
        };
        case (?space) { space };
      };
      space.puts.add(
        {
          caller = caller_;
          id = putId!;
          path = path_;
          time = timeNow_();
          user = user_;
          values = values_
        });
      putId!
    }
  };


  /// Put candid data into the space identified by the path.
  public query(msg) func get(putId : Types.PutId) : async ?Types.View.PutValues {
    do ? {
      let event = Sequence.get(eventLog_20210616_2042, putId)!;
      switch (event.kind) {
        case (#put(put)) {
               {
                 caller = put.caller;
                 path = put.path;
                 time = event.time;
                 user = put.user;
                 values = put.values;
               } };
        case _ { return null }
      }
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
  public shared(msg) func createView(
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
      let sizes_ = Buffer.Buffer<Nat>(0);
      let puts_ = State.Space.Puts.empty();
      var total_ = 0;
      for (target in targets_.vals()) {
        switch target {
          case (#space(path)) {
            let s = state.spaces.get(path)!;
            // space clone is "immutable copy" stored by view.
            spaces_.add(State.Space.clone(s));
            sizes_.add(s.puts.size());
            total_ += s.puts.size();
            puts_.append(s.puts); // gathering_ == #sequence
          };
          case (#view(viewId)) {
            loop { assert false };
          };
        }
      };
      let createEvent_ =
        {
          caller = msg.caller;
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
          spaces = spaces_.toArray();
          puts = puts_;
        });
      { viewId = id;
        putCount = {
          total = total_;
          target = sizes_.toArray();
        } }
    }
  };


  /// Get a full image (entire view) of gathered puts.
  /// May fail to complete if the view is too large;
  /// For "too large" views, use `getSubImage` multiple times, with tuning.
  public query(msg) func getFullImage(
    viewer_ : ?UserId,
    viewId_ : ViewId) : async ?Image {
    do ? {
      let v = state.views.get(viewId_)!;
      let b = Buffer.Buffer<Types.View.PutValues>(0);
      for (p in v.puts.vals()) {
        b.add({ path = p.path ;
                time = p.time ;
                user = p.user ;
                values = p.values ;
                caller = p.caller ;
              })
      };
      { pos = 0;
        size = b.size();
        viewer = viewer_;
        viewId = viewId_;
        putValues = b.toArray();
      }
    }
  };

  public query(msg) func logTail() : async ?[State.Event.Event] {
    // 20210614-1712 no access checks, for now.
    // 20210614-1712 to do -- access checks that filter out or redact the log.
    do ? {
      let tail = Buffer.Buffer<State.Event.Event>(0);
      let iter = Sequence.iter(eventLog_20210616_2042, #bwd);
      var count = 0;
      while (tail.size() < 10) {
        switch (iter.next()) {
          case null { return ?tail.toArray() };
          case (?e) { tail.add(e); }
        }
      };
      tail.toArray()
    }
  };

  /// Get a sub-image of gathered puts.
  public query(msg) func getSubImage(
    viewer_ : ?UserId,
    viewId_ : ViewId,
    pos_ : ViewPos,
    size_ : Nat) : async ?Image {
    do ? {
      let v = state.views.get(viewId_)!;
      let b = Buffer.Buffer<Types.View.PutValues>(0);
      let s = v.puts.slice(pos_, size_);
      for (p in s.vals()) {
        b.add({ path = p.path ;
                caller = p.caller ;
                time = p.time ;
                user = p.user ;
                values = p.values ;
              })
      };
      assert b.size() == size_;
      { pos = pos_;
        size = b.size();
        viewer = viewer_;
        viewId = viewId_;
        putValues = b.toArray();
      }
    }
  };
}
