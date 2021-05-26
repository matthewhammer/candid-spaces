#!ic-repl -r http://localhost:8000

import CanCan = "rwlgt-iiaaa-aaaaa-aaaaa-cai";

identity Alice;

call CanCan.createProfile("alice", null);
assert _ != (null : opt null);

identity Bob;

call CanCan.getProfileInfo("alice", null); // fail: no profile for bob yet.
assert _ == (null : opt null);

call CanCan.createProfile("bob", null); // ok.
assert _ != (null : opt null);

call CanCan.getProfileInfo("alice", null); // ok
assert _ != (null : opt null);

