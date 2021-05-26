import Hash "mo:base/Hash";
import Prelude "mo:base/Prelude";
import Text "mo:base/Text";
import Int "mo:base/Int";
import Trie "mo:base/Trie";
import TrieMap "mo:base/TrieMap";

// import non-base primitives
import Access "Access";
import Role "Role";
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

  public module Event {

    public type CreateProfile = {
      userName : Text;
    };

    public type EventKind = {
      #reset : Types.TimeMode;
      #createProfile : CreateProfile;
    };

    public type Event = {
      id : Nat; // unique ID, to avoid using time as one (not always unique)
      time : Int; // using mo:base/Time and Time.now() : Int
      kind : EventKind;
    };

    public func equal(x:Event, y:Event) : Bool { x == y };
    public type Log = SeqObj.Seq<Event>;
  };

  public type State = {
    access : Access.Access;

    /// event log.
    eventLog : Event.Log;
    var eventCount : Nat;

    /// all profiles.
    profiles : Map<Types.UserId, Profile>;
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
    };
    st
  };

}
