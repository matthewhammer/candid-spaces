//import CandidSpaces "canister:CandidSpaces";

import Types "../library/Types";

import List "mo:base/List";

actor {

  type Logger = Types.CandidSpacesActor;

  let logger : Logger =
    (actor
     /* "rrkah-fqaaa-aaaaa-aaaaq-cai" */
        "fzcsx-6yaaa-aaaae-aaama-cai"
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

  // one-way function, calling a one-way function
  public func putTextQuick(t : Text) : () {
    ourState := #Text t;
    logger.putQuick("demoDoer", ["demo", "state"], [ #Text t ]);
  };

  // one-way function, calling a one-way function
  public func putBoolQuick(b : Bool) : () {
    ourState := #Bool b;
    logger.putQuick("demoDoer", ["demo", "state"], [ #Bool b ]);
  };

  // one-way function, calling a one-way function
  public func putNatQuick(n : Nat) : () {
    ourState := #Nat n;
    logger.putQuick("demoDoer", ["demo", "state"], [ #Nat n ]);
  };
}
