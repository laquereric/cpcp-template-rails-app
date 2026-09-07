Rails.application.routes.draw do
  # THE SEAM. A CPCP application serves /_cpcp and this is where it is mounted.
  #
  # The operations behind it are NOT here -- they live in the projection
  # (config/initializers/rails_cpcp.rb), so a reader of this file sees the mount
  # and learns what it answers from the CID, not from the route table.
  mount RailsCpcp::Engine => "/_cpcp"

  get "up" => "rails/health#show", as: :rails_health_check

  # Your application's routes go here. Everything above is the template.
end
