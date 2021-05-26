import Hash "mo:base/Hash";
import Prelude "mo:base/Prelude";
import Text "mo:base/Text";
import Int "mo:base/Int";
import Trie "mo:base/Trie";
import TrieMap "mo:base/TrieMap";

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
    public type Put = {
      user : Types.UserId;
      path : Path;
      values : [Types.Candid.Value.Value];
    };
    public type EventKind = {
      #reset : Types.TimeMode;
      #createProfile : CreateProfile;
      #put : Put;
    };

    public type Event = {
      id : Nat; // unique ID, to avoid using time as one (not always unique)
      time : Int; // using mo:base/Time and Time.now() : Int
      kind : EventKind;
    };

    public func equal(x:Event, y:Event) : Bool { x == y };
    public type Log = SeqObj.Seq<Event>;
  };

  public module Space {
    /// Space of puts.
    public type Space = {
      createUser : Types.UserId;
      createTime : Int;
      puts : Puts.Puts;
    };

    public module Puts {
      /// Sequence of puts to a common space.
      public type Puts = SeqObj.Seq<PutValues.PutValues>;

      /// Empty (initial state).
      public func empty() : Puts {
        SeqObj.Seq<PutValues.PutValues>(PutValues.equal, null)
      };
    };

    /// The values of a single put operation.
    public module PutValues {
      public type PutValues = {
        time : Int;
        user : Types.UserId;
        values : [Types.Candid.Value.Value];
      };
      public func equal(pv1: PutValues, pv2: PutValues) : Bool {
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
    };
    st
  };

}
