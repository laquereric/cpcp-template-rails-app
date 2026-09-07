# cpcp-template-rails-app

Start a Rails application that serves a [CPCP](https://github.com/laquereric/coordination-protocol-contract-package)
seam. **Rails at root**, standard layout — the CPCP parts are a mount, a
projection, and a manifest.

```bash
ruby bin/check-template.rb    # structure, wiring, and the live reference
```

## It points at something running

An agent that finds this repo can reach the service that serves the endpoints
described here:

```
https://magenticmarket.ai/_cpcp/cid.json  ->  build.list, build.get, build.create
```

That is `reference_instance` in `.cpcp/package.json`, and it is not decorative:
`bin/check-template.rb` **fetches that CID and compares** what this template
claims against what the service actually publishes. Claim an operation it does
not serve and the check fails with both lists.

A template describing a seam that exists nowhere is a shape with no referent —
an agent cannot see a real response, cannot check a client against one, and
cannot tell a live contract from an aspirational one. Rule 10 of the repo
format exists for that, and this is what satisfying it looks like.

## One image, three roles — split by Rails namespace

| `ROLE` | draws | holds |
|---|---|---|
| `back` | `mount RailsCpcp::Engine => "/_cpcp"` | the database |
| `front` | `Front::` controllers | **no database** |
| `backjob` | nothing; `bin/jobs` is the entry point | no ingress |

**Roles are namespaces, not a conditional inside one route table.** The
boundary is a directory — `app/controllers/front`, `app/controllers/back` — so
it is visible in the tree, greppable, and *enforceable*. A role branch that
existed only in `routes.rb` would leave the two roles' code interleaved
everywhere else.

The URL of the seam does not change with the namespace: `/_cpcp` is `/_cpcp`
because that is the contract. Namespacing controllers is an internal fact.

### Why the split is worth the trouble

FRONT reaching BACK over CPCP puts an envelope, an `operationId` and a refusal
record between an intent and its effect — **without anyone adding a policy
layer**. That is a property of the boundary existing, which is why governance
can arrive later without rewriting callers.

```
config/routes.rb                       draws ONE role's routes
config/initializers/rails_cpcp.rb      the projection: what the seam answers
app/controllers/front/base_controller.rb   pull / push; the only way out of FRONT
app/controllers/back/                  usually empty, and that is deliberate
app/agents/                            the Agent <-> Application interface (Python)
Archspec.rb                            the boundary rules
.cpcp/package.json                     what this repo is, machine-readable
bin/check-template.rb                  the validator, in Ruby
```

## The rules in `Archspec.rb`

**FRONT may not reference models or `Back::`.** It holds no database and shares
no process. A model reference is FRONT reaching past the seam it exists to go
through; a `Back::` reference is two containers pretending to be one. Both are
planted and both fail.

**No app code may reach `RailsCpcp::Registry`, `::Dispatcher` or `::Engine`** —
the seam's own machinery. Reaching it bypasses the dispatcher and everything
that makes the boundary auditable.

`RailsCpcp::Client` is *permitted*, deliberately. The first draft of this rule
forbade `RailsCpcp` outright and immediately caught `Front::BaseController`
using the client — which is the opposite of a bypass: the client is how FRONT
goes **through** the seam. Naming the bypass rather than the library is the fix.

**`app/agents` stays Ruby-free.** The declarations there are Python, read
statically and never executed. A `.rb` beside them would sit outside every gate.

## Two checkers in CI, and neither subsumes the other

`check-repo-format.py` (from the contract, fetched at the revision this repo
pins) holds the `.cpcp` manifests. `bin/check-template.rb` holds everything
this template claims that is not a manifest. Running one is checking half of
what is promised.

## Why Rails at root

A template is judged by whether the people who will copy it recognise it. A
Ruby developer opening this expects `app/`, `config/`, `bin/`, `test/` where
Rails puts them. Every template in this family follows its own language's
conventions for the same reason — see
[cpcp-template-javascript-app](https://github.com/laquereric/cpcp-template-javascript-app)
and [cpcp-template-python-mind](https://github.com/laquereric/cpcp-template-python-mind).

## What is deliberately missing

No database, no FRONT, no agents. A CPCP unit is four roles and this is one of
them; a copy brings its own application. `app/agents/` ships the convention and
an empty roster, because inventing an agent would be a template asserting
capability it has not got.
