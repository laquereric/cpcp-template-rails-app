# ONE IMAGE, THREE ROLES. The role decides which namespace is drawn.
#
# ROLE=back      the seam. Mounts /_cpcp and nothing else.
# ROLE=front     the UI. Draws Front:: and reaches BACK over CPCP.
# ROLE=backjob   no ingress. Draws nothing; bin/jobs is the entry point.
#
# NAMESPACES, NOT CONDITIONALS INSIDE ONE SET OF ROUTES. The boundary between
# FRONT and BACK is a directory -- app/controllers/front, app/controllers/back --
# so it is visible in the tree, greppable, and enforceable by Archspec.rb. A
# role branch that only existed in this file would leave the two roles' code
# interleaved everywhere else.
#
# The URL of the seam does not change with the namespace: /_cpcp is /_cpcp
# because that is the contract. Namespacing controllers is an internal fact.
#
# A LOCAL, not a constant. "ROLE" is a word half the world uses, and planting it
# on Object from a routes file is how two libraries end up disagreeing about
# what it means. The draw block closes over it.
role = ENV.fetch("ROLE", "back")

Rails.application.routes.draw do
  # Liveness is every role's, including the one with no ingress to speak of.
  get "up" => "rails/health#show", as: :rails_health_check

  case role
  when "back"
    # THE SEAM. The operations behind it are not here -- they live in the
    # projection (config/initializers/rails_cpcp.rb), so a reader of this file
    # sees the mount and learns what it answers from the CID.
    #
    # BACK draws no UI. Serving a page from the authoritative writer is how a
    # browser ends up one redirect away from domain state.
    mount RailsCpcp::Engine => "/_cpcp"

  when "front"
    # FRONT holds no database and mounts no engine. Every read and every write
    # is a CPCP call to BACK -- which is what puts an envelope, an operationId
    # and a refusal record between an intent and its effect.
    root "front/pages#index"
    # Your UI routes go here, all under the Front:: namespace:
    #   resources :things, controller: "front/things"

  when "backjob"
    # Nothing. A worker that listened would be a BACK with extra steps.

  else
    raise ArgumentError, "unknown ROLE #{role.inspect}: expected back, front or backjob"
  end
end
