# Caniput

Candid Spaces in-*put*ting tool, for generic candid data.

## Examples

`caniput text here 'variant { Coffee = record { quantity = (1 : nat) ; how = variant { Black } } }'`

- Parses the candid `text` value `variant { Coffee = ... }`
- Puts the parsed AST into path `"here"`, on the default CandidSpaces canister.

For more usage info, try

`caniput -h`

To learn about

 - Specifying the transport layer (replica URL or network name).
 - Specifying the canister ID.

## Status

WIP.

### Working now

- Read candid values as text argument.
- Connect to Candid Spaces as a canister on local replica (for now).
- Put candid values into CandidSpaces in a "generic AST form".

### Backlog

- Main network connections.
- Export data from CandidSpaces canister to local disk.
