//import CandidSpaces "canister:CandidSpaces";

import Types "../library/Types";

actor {

  type CandidSpaces = actor {
    put : Types.Put;


  };

  let CandidSpaces : CandidSpaces = (actor "fzcsx-6yaaa-aaaae-aaama-cai" : CandidSpaces);

  stable var ourState : Nat = 0;

  public query func getSomething() : async ?Nat {
    ?ourState;
  };

  public func putSomething(n : Nat) : async ?() {
    ourState := n;
    ?()
  };  
}
