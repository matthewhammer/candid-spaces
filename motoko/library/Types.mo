/// Public-facing types.
module {

public type Timestamp = Int; // See mo:base/Time and Time.now()

public type UserId = Text; // chosen by createUser
public type ViewId = Text; // chosen by createView
public type PutId = Nat; // chosen by put

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
  /// A Path identifies a space for data to be put, and later, viewed.
  public module Path {
    public type Path = [Text];
  };

  public type Put = shared (
    user : UserId,
    path : Path.Path,
    values : [ Candid.Value.Value ] ) -> async ?PutId;

  public type Get = shared (putId : PutId) -> async ?View.PutValues;

};

public type CandidSpacesActor = actor {
  // response PutId uniquely identifies the put operation in a global log.
  put : (
    user : UserId,
    path : Space.Path.Path,
    values : [ Candid.Value.Value ] ) -> async ?PutId;

  // one-way function (no return value).
  // (inspect the log later to see where it appears, and how it is identified).
  putQuick : (
    user : UserId,
    path : Space.Path.Path,
    values : [ Candid.Value.Value ] ) -> ();

  // query function (no mutation).
  get : query (putId : PutId) -> async ?View.PutValues;
};

public module Candid {
  public module Value {
    /// Candid Value AST.
    /// [Compare with definition in Rust](https://github.com/dfinity/candid/blob/bb84807217dad6e69c78de0403030e232efaa43e/rust/candid/src/parser/value.rs#L13).
    /// We use (non-standard-in-Motoko) variant names for two reasons:
    /// 1. by being uppercase, they avoid candid keyword-parsing issues with ic-repl.
    /// 2. they directly match the Rust names, so they are still "standard"-ish.
    ///
    public type Value = {
      #Bool : Bool;
      #Null;
      #Text : Text;
      #Number : Text;
      #Opt : Value;
      #Vec : [ Value ];
      #Record : [ Field ];
      #Variant : Field;
      #Principal : Principal;
      #Service : Principal;
      #Func : (Principal, Text);
      #None;
      #Int : Int;
      #Nat : Nat;
      #Nat8 : Nat8;
      #Nat16 : Nat16;
      #Nat32 : Nat32;
      #Nat64 : Nat64;
      #Int8 : Int8;
      #Int16 : Int16;
      #Int32 : Int32;
      #Int64 : Int64;
      #Float32 : Float;
      #Reserved;

      /// Extension: Inject local filesystem structure, mixed with candid value structure.
      #File : File;
    };
    public type Label = {
      #Id : Nat32;
      #Named : Text;
      #Unnamed : Nat32;
    };
    public type Field = {
      id : Label;
      val : Value;
    };
    public type Args = {
      args : [ Value ];
    };
    /// Local filesystem structure, with optional candid value structure inside.
    public type File = {
      /// Ordinary directory of (named) files.
      #Directory : [ NamedFile ];
      /// Candid-encoded value, in a file.
      #Value : Value;
      /// Candid-encoded arguments, in a file.
      #Args : Args;
      /// Ordinary text file
      #Text : Text;
      /// Ordinary binary file
      #Binary : [ Nat8 ];
    };

    public type NamedFile = {
      name : Text;
      file : File;
    };
  }
};

public module View {

  /// A `Gathering` answers the question:
  /// How to gather put values to form a View?
  public type Gathering = {
    /// preserve ordering of puts, and append those of gathered spaces.
    /// initially, we only support #sequence.
    #sequence ;
    /// to do -- gather equal data values, and count them.
    #multiset ;
    /// to do -- like multiset but without per-element counts.
    #set ;
    /// to do -- like multiset, but additionally sort based on count.
    #multisetSort : SortDir ;
  };

  /// sort direction
  public type SortDir = {
    #decreasing;
    #increasing
  };

  /// `Targets` names a sequence of spaces to gather into a View.
  /// When spaces are numerous and each small,
  /// the user creates views that aggregate many paths' data.
  /// Views can include the data of other views, which retains its (origin)
  /// path information.
  ///
  /// `createView` accepts `Targets`,
  /// and each View it creates contains specific path information for its data,
  /// accessible via `getFullView` and `getSubView`.
  public module Target {
    public type Target = {
      #space : Space.Path.Path;
      #view : ViewId;
    };
    public type Targets = [ Target ];
  };

  /// Type of `CandidSpaces.createView` relates other types defined here.
  ///
  /// `createView` accepts a collection of view targets, and gathers them;
  /// each full or sub-view it provides contains specific path information for its data,
  /// accessible via `getFullView` and `getSubView`, respectively.
  ///
  /// It returns a record of size information about the full view, and
  /// size information to guide accesses to spaces within it, as subviews.
  ///
  public type CreateView =
    (user_ : UserId,
     targets_ : Target.Targets,
     gathering_ : Gathering,
     ttl_ : ?Nat) -> async ?CreateViewResponse;

  /// The response type of `CandidSpaces.createView`.
  /// gives size information about the full view, and targets within it.
  /// this size information may be used to guide the definition of subviews.
  /// the `putCount.path[i]` is the size of path `i`, in number of put operations.
  public type CreateViewResponse = {
    viewId : ViewId;
    putCount : {
      target : [Nat];
      total : Nat;
    }
  };

  /// Each `PutValues` record represents an atomic `CandidSpaces.put` update message.
  /// It associates a time, user and path with a candid data sequence.
  /// A put value is an atomic "raw data" entry of a space, as viewed by a View.
  public type PutValues = {
    caller : Principal;
    time : Timestamp;
    user : UserId;
    path : Space.Path.Path;
    values : [ Candid.Value.Value ];
  };

  /// Get a full image (entire view) of gathered puts.
  /// May fail to complete if the view is too large;
  /// For "too large" views, use `getSubImage` multiple times, with tuning.
  public type GetFullImage =
    (viewer : ?UserId,
     viewId : ViewId) -> async ?Image;

  /// Get a sub-image of gathered puts.
  /// Positions are in terms of total gathered puts.
  public type GetSubImage = (
    viewer : ?UserId,
    viewId : ViewId,
    pos : Position,
    size : Nat) -> async ?Image;

  /// The `Image` type defines the (common) response type of
  /// `CandidSpaces.getFullImage` and `CandidSpaces.getSubImage`.
  public type Image = {
    viewer : ?UserId;
    viewId : ViewId;
    pos : Position;
    size : Nat;
    putValues : [ PutValues ];
  };

  /// Positions are in terms of total gathered puts.
  public type Position = Nat;
};


/// For test scripts, the script controls how time advances, and when.
/// For real deployment, the service uses the IC system as the time source.
public type TimeMode = { #ic ; #script : Timestamp };

}
