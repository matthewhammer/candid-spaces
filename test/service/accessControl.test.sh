#!ic-repl -r http://localhost:8000

// service address
import S = "rwlgt-iiaaa-aaaaa-aaaaa-cai";

identity Alice;

call S.createProfile("alice", null);
assert _ != (null : opt null);

identity Bob;

call S.getProfileInfo("alice"); // fail: no profile for bob yet.
assert _ == (null : opt null);

call S.createProfile("bob"); // ok.
assert _ != (null : opt null);

call S.getProfileInfo("alice"); // ok
assert _ != (null : opt null);

