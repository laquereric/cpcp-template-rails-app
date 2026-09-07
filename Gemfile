source "https://rubygems.org"

gem "rails", "~> 8.0"

# The glue: mounts /_cpcp, dispatches the envelope, holds idempotency receipts.
gem "rails-cpcp"

group :development, :test do
  # Executable architecture (Archspec.rb). Static analysis; never boots the app.
  gem "archspec", require: false
end
