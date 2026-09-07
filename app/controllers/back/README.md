# app/controllers/back

Usually empty, and that is not an oversight.

BACK serves `/_cpcp` through the mounted `RailsCpcp::Engine`; the operations
behind it are declared in `config/initializers/rails_cpcp.rb`, not written as
controllers. A controller here would be a second way into domain state, beside
the seam that exists to be the only one.

Put something here when BACK genuinely needs a non-CPCP surface — a health
probe richer than `/up`, an operator page bound to the authoritative writer.
When you do, it stays namespaced `Back::` so the boundary remains a directory
rather than a convention someone has to remember.
