# Candid Spaces

## What?

- A [social](https://en.wikipedia.org/wiki/Social_media)
- [Candid data](https://github.com/dfinity/candid) [Data lake](https://en.wikipedia.org/wiki/Data_lake)
- for the [Internet Computer](https://internetcomputer.org/).

## How?

### Put candid values into spaces via `caniput`

#### Text (strings)

Subcommand `text`:

`caniput -r https://ic0.app -c fzcsx-6yaaa-aaaae-aaama-cai text here "hello world"`

Puts the `text` `"hello world"` into the space at path `here`.

The option `-r` specifies the URL of the IC, or the local replica (default).

The option `-c` specifies the CandidSpaces canister ID.

#### Candid values

Subcommand `value`:

`caniput -r https://ic0.app -c fzcsx-6yaaa-aaaae-aaama-cai value here "vec {1; \"two\"}"`

Puts the value `vec {1; "two"}` into space `here`.

#### Trees of files

Subcommand `tree`:

`caniput -r https://ic0.app -c fzcsx-6yaaa-aaaae-aaama-cai tree here test/service/putTree`

Puts an example file tree, from [local path `test/service/putTree`](https://github.com/matthewhammer/candid-spaces/tree/main/test/service/putTree) to remote path `here`.

`caniput` distinguishes several cases:
 - Files that parse as candid arguments.
 - Files that parse as candid values.
 - Files that do not parse as candid; treated as text.
 - Directories of other files.
