# Executable architecture. Two rules, both class-wide rather than app-specific,
# both of which have caught something real in a repo built this way.
#
# Run: bundle exec archspec check
architecture :rails

# The seam is reached by CALLING it, not by reaching into the engine. A model or
# controller touching RailsCpcp::Registry bypasses the dispatcher, and with it
# the envelope, the idempotency key and the refusal record that make the
# boundary auditable. The projection is the one place that names it.
%i[controllers models helpers mailers jobs services].each do |name|
  component(name).cannot_reference_constants "RailsCpcp",
    because: "only config/initializers/rails_cpcp.rb may name the seam it is served over"
end

# app/agents holds PYTHON declarations, read statically and never executed. A
# Ruby file here would sit outside every gate that holds the agent interface.
component :agents, in: "app/agents/**/*.rb"
agents.must_be_empty(
  because: "agent declarations here are Python; see app/agents/README.md")
