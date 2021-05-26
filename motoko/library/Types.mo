/// Public-facing types.
module {

public type Timestamp = Int; // See mo:base/Time and Time.now()

public type UserId = Text; // chosen by createUser
public type ViewId = Text; // chosen by createView

/// Role for a caller into the service API.
/// Common case is #user.
public type Role = {
  // caller is a user
  #user;
  // caller is the admin
  #admin;
  // caller is not yet a user; just a guest
  #guest
};

/// Action is an API call classification for access control logic.
public type UserAction = {
  /// Create a new user name, associated with a principal and role #user.
  #create;
  /// Update an existing profile, or add to its videos, etc.
  #update;
  /// View an existing profile, or its videos, etc.
  #view;
  /// Admin action, e.g., getting a dump of logs, etc
  #admin
};

/// An ActionTarget identifies the target of a UserAction.
public type ActionTarget = {
  /// User's profile or videos are all potential targets of action.
  #user : UserId ;
  /// Everything is a potential target of the action.
  #all;
  /// Everything public is a potential target (of viewing only)
  #pubView
};

public type ProfileInfo = {
 userName: Text;
};

public module Space {
  public type Path = [Text];
  public type Paths = {
    #all;
    #within : [(Text, Paths)]
  };
  /* to do --
  public type Sort = {
    #set
    #multiset
    #sequence
  }; */
};

public module Candid {
  public module Value {
    public type Field = {
      name : Text;
      value : Value
    };
    public type Record = {
      fields : [ Field ];
    };
   /* to do --
   public type Type = ...
   */
    public type Value = {
      #opt : Value;
      #vec : [ Value ];
      #record : Record;
      #variant : Field;
      #principal : Principal;
      #none;
      #nil; // wanted #null
      #int : Int;
      #nat : Nat;
      #bool : Bool;
      #text : Text;
      #number : Text;
    };
  }
};

public module View {
  public type ChunkId = Text;
  public type Timestamp = Int;

  public type Gathering = {
    #set ;
    #multiset ;
    #sequence ;
  };

  public type ValueWithTime = {
    value : Candid.Value.Value;
    time : Timestamp;
  };

  public type ValueWithTimes = {
    value : Candid.Value.Value;
    times : [Timestamp];
  };

  public type SetChunk =
    { subSet : [ValueWithTime] };

  public type MultiSetChunk =
    { subSet : [ValueWithTimes] };

  public type SequenceChunk =
    { offset : Nat;
      subSequence : [ValueWithTime] };

  public type ChunkData = {
    #set : SetChunk;
    #multiSet : MultiSetChunk;
    #sequence : SequenceChunk;
  };
  public type Chunk = {
    id : ChunkId;
    data : ChunkData;
  };
  public type View = {
    chunk : Chunk;
    next : ?ChunkId;
  };
};

/// For test scripts, the script controls how time advances, and when.
/// For real deployment, the service uses the IC system as the time source.
public type TimeMode = { #ic ; #script : Int };

}
