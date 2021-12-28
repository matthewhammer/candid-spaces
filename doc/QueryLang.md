# Candid Spaces Query Language

## Background definitions

Consider the design of candid spaces' data, over which we query.

- Each _view target_ is itself a space or view.
- Each view target holds a sequence of `PutValues` records.
- Each `PutValues` value records an atomic `put`, including a user and timestamp, and it holds an array of Candid value ASTs that were `put`.
- Each Candid value AST is a tree whose type can be synthesized from the AST, which contains complete field and variant names, not merely their hashes (as in the Candid binary representation).

In summary, the raw data of Candid Spaces is a particular kind of table that is akin to [Candid-based telemetry data](https://en.wikipedia.org/wiki/Telemetry), and it is highly temporal.

## Query language

Each query, when issued, produces a [materialized `View`](https://en.wikipedia.org/wiki/Materialized_view) of the query's answer, similar to the `View`s produced by `createView`.

In fact, `createView` can be seen as a very impoverished language that only provides one operation: `sequenceAppend`.

The role of this document is to design a richer DSL that permits more operations, and more ways to gather and analyze Candid data for its eventual presentation by front-end software, as a list of "results".

### Sequence operations

- `append` - expressible now by `createView`.
- `slice` - expressible now by `getSubImage` on a `View`.

- `filter` - absent.
- `map` - absent.
- `sort` - absent.
- `count` - absent.

#### Candid expression DSL

The absent operatons really would benefit from another DSL that works over candid values, offering a way to pattern-match them and re-construct them, with variables.

The DSL of `ic-repl` has a related need, and a related DSL that we could adapt.

### Set operations

Each put value sequence can be treated like a set, by giving each put value its own status as a set element and (optionally) forgetting about their associated users and time.

Separately, the meta fields `time` and `user` can be used to define sets, given a sequence of put values.

### Multi-set operations

A multi-set introduces counts for the elements of a set.

### _More?_
