#!ic-repl -r http://localhost:8000

// service address
import S = "rwlgt-iiaaa-aaaaa-aaaaa-cai";

identity Alice;

call S.createProfile("alice", null);
assert _ != (null : opt null);

call S.put("alice", vec { "fib" }, vec { variant { Nat = 1 } ; variant { Nat = 1 } });
assert _ != (null : opt null);

call S.put("alice", vec { "factorial" }, vec { variant { Nat = 1 } ; variant { Nat = 1 } });
assert _ != (null : opt null);

call S.put("alice", vec { "fib" }, vec { variant { Nat = 2 } ; variant { Nat = 3 } });
assert _ != (null : opt null);

call S.put("alice", vec { "factorial" }, vec { variant { Nat = 2 } ; variant { Nat = 6 } });
assert _ != (null : opt null);

call S.put("alice", vec { "fib" }, vec { variant { Nat = 5 } ; variant { Nat = 8 } });
assert _ != (null : opt null);

call S.put("alice", vec { "factorial" }, vec { variant { Nat = 24 } ; variant { Nat = 120 } });
assert _ != (null : opt null);

call S.put("alice", vec { "colorVariants" }, vec {
           variant { Variant = record { name = "red" ; value = variant { nil } } };
           variant { Variant = record { name = "green" ; value = variant { nil } } };
           variant { Variant = record { name = "gold" ; value = variant { nil } } };
           });
assert _ != (null : opt null);

let view = call S.createView("alice",
                               vec { variant { space = vec { "fib" } };
                                     variant { space = vec { "colorVariants" } };
                                     variant { space = vec { "factorial" } } },
                               variant { sequence = null },
                               null
                              );
assert _ != (null : opt null);
view;
assert view?.putCount.total == (6 : nat);
assert view?.putCount.target[0] == (3 : nat);
assert view?.putCount.target[1] == (3 : nat);

let fullImage = call S.getFullImage(opt "alice", view?.viewId);
assert _ != (null : opt null);
fullImage;

let firstHalf = call S.getSubImage(opt "alice", view?.viewId, 0, 3);
assert _ != (null : opt null);
firstHalf;

let secondHalf = call S.getSubImage(opt "alice", view?.viewId, 3, 3);
assert _ != (null : opt null);
secondHalf;



