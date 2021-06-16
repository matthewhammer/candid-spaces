# Caniput

Candid Spaces in-*put*ting tool, for generic candid data.

## Examples

### Local replica (default)

`caniput text here 'variant { Coffee = record { quantity = (1 : nat) ; how = variant { Black } } }'`

- Parses the candid `text` value `variant { Coffee = ... }`
- Puts the parsed AST into path `"here"`, on the default CandidSpaces canister.

For more usage info, try

`caniput -h`

To learn about

 - Specifying the transport layer (replica URL or network name).
 - Specifying the canister ID.


### CandidSpaces on the IC

To access the IC with `caniput`, specify `https://ic0.app` as the replica URL with `-r`, as follows:

`caniput -r https://ic0.app -c fzcsx-6yaaa-aaaae-aaama-cai text here 1`

Specify the CandidSpaces canister with `-c` (example uses `fzcsx-6yaaa-aaaae-aaama-cai`).

The example puts the value `1` into space `here`, parsed as a `text` CLI argument.


## Status

WIP.

### Working now

- Read candid values as text argument.
- Connect to Candid Spaces as a canister on local replica, and on the IC.
- Put candid values into CandidSpaces in a "generic AST form".

### Backlog

- Export data from CandidSpaces canister to local disk.
