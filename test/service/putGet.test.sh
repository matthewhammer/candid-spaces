#!ic-repl -r http://localhost:8000

// service address
import S = "rwlgt-iiaaa-aaaaa-aaaaa-cai";

identity Alice;

call S.createProfile("alice", null);
assert _ != (null : opt null);

call S.put("alice", vec { "fib" }, vec { variant { nat = 1 } ; variant { nat = 1 } });
assert _ != (null : opt null);

call S.put("alice", vec { "fib" }, vec { variant { nat = 2 } ; variant { nat = 3 } });
assert _ != (null : opt null);

call S.put("alice", vec { "fib" }, vec { variant { nat = 5 } ; variant { nat = 8 } });
assert _ != (null : opt null);


call S.put("alice", vec { "factorial" }, vec { variant { nat = 1 } ; variant { nat = 1 } });
assert _ != (null : opt null);

call S.put("alice", vec { "factorial" }, vec { variant { nat = 2 } ; variant { nat = 6 } });
assert _ != (null : opt null);

call S.put("alice", vec { "factorial" }, vec { variant { nat = 24 } ; variant { nat = 120 } });
assert _ != (null : opt null);


// call S.put("alice", vec { "colorVariants" }, vec {
//            variant { variant = { name = "red" ; value = variant { nil } } };
//            variant { variant = { name = "green" ; value = variant { nil } } };
//            variant { variant = { name = "gold" ; value = variant { nil } } };
//           });
// assert _ != (null : opt null);


let viewId = call S.createView("alice",
                               vec { variant { space = vec { "fib" } };
                                     variant { space = vec { "factorial" } } },
                               variant { sequential = null },
                               null
                              );
assert _ != (null : opt null);

let fullImage = call S.getFullImage("alice", viewId);
assert _ != (null : opt null);