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

## What you get

```
config/routes.rb                    mounts RailsCpcp::Engine at /_cpcp
config/initializers/rails_cpcp.rb   the projection: what the seam answers
app/agents/                         the Agent <-> Application interface (Python)
Archspec.rb                         two boundary rules, both of which have
                                    caught something real
.cpcp/package.json                  what this repo is, machine-readable
bin/check-template.rb               the validator, in Ruby
```

## The two rules in `Archspec.rb`

**App code may not name `RailsCpcp`.** The seam is reached by *calling* it, not
by reaching into the engine — a model touching the registry bypasses the
dispatcher, and with it the envelope, the idempotency key and the refusal
record. Only the projection may name it. This fired on a real repo the day it
was written; the fix was to inject what the model needed instead of letting it
reach.

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
