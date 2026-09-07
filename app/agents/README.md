# app/agents

Python declarations of the Agent ↔ Application interface, in the Rails tree
beside the rest of the application surface.

Two files when you have them:

| file | direction | answers |
|---|---|---|
| `available_agents.py` | inbound | which agents are available **to** this application |
| `rails_surface.py` | outbound | this application's surface, as a Python object **in the agents' context** |

## Why `app/`, not `lib/`

These are application surface, not tooling. Zeitwerk only autoloads `.rb`, so
`.py` here is inert to Rails — the same way `app/assets` and `app/javascript`
are. Nothing boots this code.

`Archspec.rb` asserts this directory stays free of Ruby: a `.rb` file here means
someone began implementing agents beside the declarations, where nothing holds
the two halves together.

## Declarations are data, and are read without being run

Module-level literals only. No imports, no computation, no side effects at
module scope, because the checker reads them with `ast.literal_eval` and
**never executes them**. A gate that imports the thing it checks runs whatever
that file happens to do.

If a value cannot be written as a literal, it does not belong in a declaration.

## Empty is a claim

`AVAILABLE_AGENTS = []` with a `BECAUSE` saying why is conforming, and is what
a new application should start with. An omitted roster cannot be told apart
from an overlooked one.

This template ships no agents for that reason: inventing one would be a
template asserting capability it has not got.
