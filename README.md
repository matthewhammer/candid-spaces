# Candid Spaces

## What?

- A [social](https://en.wikipedia.org/wiki/Social_media)
- [Candid data](https://github.com/dfinity/candid) [Data lake](https://en.wikipedia.org/wiki/Data_lake)
- for the [Internet Computer](https://internetcomputer.org/).

## How?

### Deploy with `dfx deploy`

`dfx deploy --network=ic CandidSpaces`

In the examples below, the deployed canister ID is [`fzcsx-6yaaa-aaaae-aaama-cai`](https://ic.rocks/principal/fzcsx-6yaaa-aaaae-aaama-cai).

You can use this canister ID to play with `caniput`, and optionally, may deploy your own, for private use.

### Put candid values into spaces via `caniput`

See [`caniput` subdirectory](https://github.com/matthewhammer/candid-spaces/tree/main/rust/caniput) for details.

#### Put text

Subcommand `text`:

`caniput -r https://ic0.app -c fzcsx-6yaaa-aaaae-aaama-cai text here "hello world"`

Puts the `text` `"hello world"` into the space at path `here`.

#### Put candid values

Subcommand `value`:

`caniput -r https://ic0.app -c fzcsx-6yaaa-aaaae-aaama-cai value here "vec {1; \"two\"}"`

Puts the value `vec {1; "two"}` into space `here`.

See type `Value` in [`CandidSpaces.did`](https://github.com/matthewhammer/candid-spaces/tree/CandidSpaces.did) for details.

#### Put trees of files

Subcommand `tree`:

`caniput -r https://ic0.app -c fzcsx-6yaaa-aaaae-aaama-cai tree here test/service/putTree`

Puts an example file tree, from [local path `test/service/putTree`](https://github.com/matthewhammer/candid-spaces/tree/main/test/service/putTree) to remote path `here`.

`caniput tree` distinguishes several cases:
 - Files that parse as candid arguments.
 - Files that parse as candid values.
 - Files that do not parse as candid; treated as text.
 - Directories of other files.

See type `File` in [`CandidSpaces.did`](https://github.com/matthewhammer/candid-spaces/tree/CandidSpaces.did) for details.
