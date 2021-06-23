//import CandidSpaces "canister:CandidSpaces";

import Types "../library/Types";

import List "mo:base/List";

actor {

  type Logger = Types.CandidSpacesActor;

  let logger : Logger =
    (actor "rrkah-fqaaa-aaaaa-aaaaq-cai" /*"fzcsx-6yaaa-aaaae-aaama-cai"*/
       : Logger);

  public type PutId = Types.PutId;

  public type OurState = {
    #Nat : Nat;
    #Bool : Bool;
    #Text : Text;
  };

  stable var ourState : OurState = #Nat 0;

  stable var ourLogPuts : List.List<PutId> = null;

  public query func greet() : async Text {
    "hello 202106171528";
  };

  func doStateChange(newState : OurState) : async ?() {
    do ? {
      ourState := newState;
      let p = await logger.put("demoDoer", ["demo", "state"], [ newState ]);
      ourLogPuts := ?(p!, ourLogPuts);
    };
  };

  func doStateChangeQuick(newState : OurState) : async ?() {
    do ? {
      ourState := newState;
      // Notice: no await here! --- So, should be quicker than non-Quick version.
      // Trade-off is that the put result is not available until we do await it, and we dont.
      let _ = logger.put("demoDoer", ["demo", "state"], [ newState ]);
    };
  };

  public query func getState() : async ?{state : OurState; logPuts : [PutId]}
  {
    ?{ state = ourState ;
       logPuts = List.toArray(ourLogPuts) }
  };

  public func putText(t : Text) : async ?() {
    await doStateChange(#Text t)
  };

  public func putBool(b : Bool) : async ?() {
    await doStateChange(#Bool b)
  };

  public func putNat(n : Nat) : async ?() {
    await doStateChange(#Nat n)
  };

  public func putTextQuick(t : Text) : async ?() {
    await doStateChangeQuick(#Text t)
  };

  public func putBoolQuicker(b : Bool) : async ?() {
    await doStateChangeQuick(#Bool b)
  };

  public func putNatQuicker(n : Nat) : async ?() {
    await doStateChangeQuick(#Nat n)
  };
}
