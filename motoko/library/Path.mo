import Hash "mo:base/Hash";
import Prim "mo:⛔";

module {
  public type Path = [Text];    

  public func equal(p1 : Path, p2: Path) : Bool {
    p1 == p2
  };

  public func hash(p : Path) : Hash.Hash {
    var x : Nat32 = 5381;
    for (text in p.vals()) {
      for (char in text.chars()) {
        let c : Nat32 = Prim.charToNat32(char);
        x := ((x << 5) +% x) +% c;
      };
      x := ((x << 5) +% x) +% 137;
    };
    return x
  };

}
