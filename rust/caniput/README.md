# Caniput

Candid Spaces in-*put*ting tool, for generic candid data.


## Examples

### Put text

Subcommand `text`:

`caniput -r https://ic0.app -c fzcsx-6yaaa-aaaae-aaama-cai text here "hello world"`

Puts the `text` `"hello world"` into the space at path `here`.

### Put candid values

Subcommand `value`:

`caniput -r https://ic0.app -c fzcsx-6yaaa-aaaae-aaama-cai value here "vec {1; \"two\"}"`

Puts the value `vec {1; "two"}` into space `here`.

See type `Value` in [`CandidSpaces.did`](https://github.com/matthewhammer/candid-spaces/tree/CandidSpaces.did) for details.

### Put trees of files

Subcommand `tree`:

`caniput -r https://ic0.app -c fzcsx-6yaaa-aaaae-aaama-cai tree here test/service/putTree`

Puts an example file tree, from [local path `test/service/putTree`](https://github.com/matthewhammer/candid-spaces/tree/main/test/service/putTree) to remote path `here`.

`caniput tree` distinguishes several cases:
 - Files that parse as candid arguments.
 - Files that parse as candid values.
 - Files that do not parse as candid; treated as text.
 - Directories of other files.

See type `File` in [`CandidSpaces.did`](https://github.com/matthewhammer/candid-spaces/tree/CandidSpaces.did) for details.


## Status

WIP.

### Working now

- Read candid values as text argument.
- Connect to Candid Spaces as a canister on local replica, and on the IC.
- Put candid values into CandidSpaces in a "generic AST form".

### Backlog

- Export data from CandidSpaces canister to local disk.
