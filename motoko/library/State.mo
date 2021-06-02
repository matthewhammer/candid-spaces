import Hash "mo:base/Hash";
import Prelude "mo:base/Prelude";
import Text "mo:base/Text";
import Int "mo:base/Int";
import Trie "mo:base/Trie";
import TrieMap "mo:base/TrieMap";

import Seq "mo:sequence/Sequence";

// import non-base primitives
import Access "Access";
import Role "Role";
import Path "Path";
import Rel "Rel";
import RelObj "RelObj";
import SeqObj "SeqObj";

// types in separate file
import Types "./Types";

/// Internal CanCan canister state.
module {

  // Our representation of (binary) relations.
  public type RelShared<X, Y> = Rel.RelShared<X, Y>;
  public type Rel<X, Y> = RelObj.RelObj<X, Y>;

  // Our representation of finite mappings.
  public type MapShared<X, Y> = Trie.Trie<X, Y>;
  public type Map<X, Y> = TrieMap.TrieMap<X, Y>;

  public type Path = Types.Space.Path.Path;

  public module Event {
    public type CreateProfile = {
      userName : Text;
    };
    public type CreateView = {
      createUser : Types.UserId;
      createTime : Int;
      targets : Types.View.Target.Targets;
      gathering : Types.View.Gathering;
      ttl : ?Nat;
    };
    public type Put = {
      user : Types.UserId;
      path : Path;
      values : [ Types.Candid.Value.Value ];
    };
    public type EventKind = {
      #reset : Types.TimeMode;
      #createProfile : CreateProfile;
      #createView : CreateView;
      #put : Put;
    };

    public type Event = {
      id : Nat; // unique ID, to avoid using time as one (not always unique); need not be sequential.
      time : Int; // using mo:base/Time and Time.now() : Int
      kind : EventKind;
    };

    public func equal(x:Event, y:Event) : Bool { x == y };
    public type Log = SeqObj.Seq<Event>;
  };

  /// A view is an immutable representation of a gathering of paths' data.
  public module View {
    public type View = {
      createEvent : Event.CreateView;
      spaces : [Space.Space];
      puts : Space.Puts.PutSeqObj;
    };
  };

  public module Space {
    /// Space of puts.
    public type Space = {
      createUser : Types.UserId;
      createTime : Int;
      path : Path;
      puts : Puts.PutSeqObj;
    };

    /// clone a space cheaply, in O(1) time.
    /// cloned space is not affected by updates to original object;
    /// specifically, cloned space has cloned put sequence.
    public func clone(s : Space) : Space {
      { createUser = s.createUser ;
        createTime = s.createTime ;
        puts = s.puts.clone() ;
        path = s.path ;
      }
    };

    public module Puts {
      /// Sequence of puts to a common space.
      public type PutSeqObj = SeqObj.Seq<PutValue.PutValue>;

      /// Sequence of puts to a common space.
      public type PutSeq = Seq.Sequence<PutValue.PutValue>;

      /// Empty (initial state).
      public func empty() : PutSeqObj {
        SeqObj.Seq<PutValue.PutValue>(PutValue.equal, null)
      };
    };

    /// The data associated of a single put operation.
    public module PutValue {
      public type PutValue = {
        time : Int;
        user : Types.UserId;
        path : Path;
        values : [ Types.Candid.Value.Value ];
      };
      public func equal(pv1: PutValue, pv2: PutValue) : Bool {
        pv1 == pv2
      };
    };
  };

  public type State = {
    access : Access.Access;

    /// event log.
    eventLog : Event.Log;
    var eventCount : Nat;

    /// all profiles.
    profiles : Map<Types.UserId, Profile>;

    /// all spaces.
    spaces : Map<Path, Space.Space>;

    // all views.
    views : Map<Types.ViewId, View.View>;
    var viewCount : Nat;
  };

  /// User profile.
  public type Profile = {
    userName : Text ;
    createdAt : Types.Timestamp;
  };

  public func empty (init : { admin : Principal }) : State {
    let equal = (Text.equal, Text.equal);
    let hash = (Text.hash, Text.hash);
    let st : State = {
      access = Access.Access({ admin = init.admin });
      profiles = TrieMap.TrieMap<Types.UserId, Profile>(Text.equal, Text.hash);
      eventLog = SeqObj.Seq<Event.Event>(Event.equal, null);
      var eventCount = 0;
      spaces = TrieMap.TrieMap<Path, Space.Space>(Path.equal, Path.hash);
      views = TrieMap.TrieMap<Types.ViewId, View.View>(Text.equal, Text.hash);
      var viewCount = 0;
    };
    st
  };

}
