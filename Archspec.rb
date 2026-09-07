# Executable architecture. Every rule here has caught something real in a repo
# built this way, or holds a boundary the deployment depends on.
#
# Run: bundle exec archspec check

architecture :rails

# --- the seam ---------------------------------------------------------------
#
# The seam is reached by CALLING it, not by reaching into the engine. A model or
# controller touching RailsCpcp::Registry bypasses the dispatcher, and with it
# the envelope, the idempotency key and the refusal record that make the
# boundary auditable. The projection is the one place that may name it.
#
# This fired on a real repo the day it was written: a model reached for
# RailsCpcp.base_iri to build an @id. The fix was to inject it from the
# projection, which is the better shape independent of the rule.
# --- the role split ---------------------------------------------------------
#
# ROLES ARE NAMESPACES, SO THE SPLIT IS CHECKABLE. FRONT and BACK are separate
# containers at deploy time; without this they would be one codebase that merely
# happens to be started twice, and the first controller to reach a model
# directly would quietly delete the boundary that governance stands on.

# The role namespaces sit inside app/controllers, so the preset's `controllers`
# component claims the same files unless it is told not to. Without this,
# Front::PagesController inheriting Front::BaseController reads as "controllers
# depend on front" and fails -- a component overlapping a preset's is the same
# trap that produced 300 errors the first time it was hit.
component :controllers, in: "app/controllers/**/*.rb",
                        except: "app/controllers/{front,back}/**/*.rb"

component :front, in: "app/controllers/front/**/*.rb"
component :back,  in: "app/controllers/back/**/*.rb"

# NAME THE BYPASS, NOT THE LIBRARY. The first draft forbade "RailsCpcp"
# outright and caught Front::BaseController using RailsCpcp::Client -- which is
# the opposite of a bypass: the client is how FRONT goes THROUGH the seam. What
# must not be reached from app code is the SERVER side: the registry that holds
# the operations and the dispatcher that runs them.
%i[controllers front back models helpers mailers jobs services].each do |name|
  component(name).cannot_reference_constants(
    "RailsCpcp::Registry", "RailsCpcp::Dispatcher", "RailsCpcp::Engine",
    because: "these are the seam's own machinery. Reaching them from app code " \
             "bypasses the dispatcher, and with it the envelope, the " \
             "idempotency key and the refusal record that make the boundary " \
             "auditable. Declare operations in the projection; call them with " \
             "RailsCpcp::Client.")
end


# One rule, because ArchSpec keys a rule to the component pair and both
# targets are the same bypass seen at two distances.
front.cannot_use :models, :back,
  because: "FRONT holds no database and shares no process with BACK. Every read " \
           "and every write is a CPCP call -- which is what puts an envelope, an " \
           "operationId and a refusal record between an intent and its effect. A " \
           "model reference is FRONT reaching past the seam it exists to go " \
           "through; a Back:: reference is two containers pretending to be one, " \
           "and co-locating FRONT and BACK is not a conformant CPCP deployment."

front.cannot_call :establish_connection, :connection, :transaction,
  because: "FRONT has no database connection to establish. Reaching for one is " \
           "the same bypass as touching a model, one layer down."

# --- the agent interface ----------------------------------------------------
#
# app/agents holds PYTHON declarations, read statically and never executed. A
# Ruby file here would sit outside every gate that holds the agent interface.
component :agents, in: "app/agents/**/*.rb"
agents.must_be_empty(
  because: "agent declarations here are Python; see app/agents/README.md")
