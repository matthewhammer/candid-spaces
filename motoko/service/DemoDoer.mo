//import CandidSpaces "canister:CandidSpaces";

import Types "../library/Types";

import List "mo:base/List";

actor {

  type Logger = Types.CandidSpacesActor;

  let logger : Logger =
    (actor "fzcsx-6yaaa-aaaae-aaama-cai"
       : Logger);

  public type PutId = Types.PutId;

  public type OurState = {
    #Nat : Nat;
    #Bool : Bool;
    #Text : Text;
  };

  stable var ourState : OurState = #Nat 0;

  stable var ourLogPuts : List.List<PutId> = null;

  func doStateChange(newState : OurState) : async ?() {
    do ? {
      ourState := newState;
      let p = await logger.put("demoDoer", ["demo", "state"], [ newState ]);
      ourLogPuts := ?(p!, ourLogPuts);
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
}
