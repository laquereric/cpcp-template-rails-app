# frozen_string_literal: true
#
# THE PROJECTION: what this application answers on the seam.
#
# One place names RailsCpcp, and this is it. Archspec.rb forbids app code from
# naming it, so anything the operations need -- a base IRI, a store, a clock --
# is passed IN from here rather than reached for from inside a model. That rule
# fired on a real repo the day it was written; the fix was this shape.
RailsCpcp.base_iri = ENV.fetch("CPCP_BASE_IRI", "https://example.test")

Rails.application.config.after_initialize do
  # Replace with your own resource. `model:` is a STRING used to build the type
  # IRI -- it does not have to be an ActiveRecord class, and a curated file is
  # often the more honest representation of a small closed set.
  RailsCpcp.project(model: "Thing") do
    operation "thing.list", direction: :pull, result: :collection,
      summary: "List the things this application publishes",
      via: ->(_params, _ctx) { [] }

    # PUSH carries an operationId and is idempotent by it. Declare a push only
    # when something durable changes; a read that pretends to be a write costs
    # you the receipt machinery for nothing.
    #
    # operation "thing.create", direction: :push, params: %w[name],
    #   summary: "Create a thing (PUSH; idempotent by operationId)",
    #   via: ->(params, _ctx) { ... }
  end
end
