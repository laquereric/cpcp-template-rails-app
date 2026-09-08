source "https://rubygems.org"

gem "rails", "~> 8.0"

# JSON BELOW 3.0, BECAUSE RAILS 8.1 CANNOT CALL IT.
#
# Carried by this template because a starting point's whole job is to hand down
# the things somebody would otherwise lose a day to.
#
# ActiveSupport depends on "json" with NO version constraint, so bundler
# resolves the newest, and activesupport-8.1.3.1 then calls
#
#     ::JSON.parse(json, options)      # json/decoding.rb:25, two positional args
#
# against json 3.0.0's `parse(source, on_load:, object_class:, array_class:,
# **options)`, which takes one. ActiveSupport::JSON.decode raises ArgumentError,
# and with it ActiveRecord::Type::Json#deserialize -- every JSON column in the
# app you are about to build.
#
# EXPECT IT TO PRESENT NOWHERE NEAR ITS CAUSE. The ArgumentError fires during
# transaction ROLLBACK, where Rails re-casts attributes, so it REPLACES whatever
# error caused the rollback. On a real deployment two CPCP operations refused
# with a bare processing_failed and no cause attached; both passed their shape
# checks against the handler and failed only through the seam, and finding json
# needed a backtrace from inside the adapter.
#
# The platform base pins json too, and that is NOT sufficient -- measured, not
# assumed: with the base at 2.21.2, an app running its own bundle install still
# resolved 3.0.0. An app resolves its own bundle, so an app needs its own pin.
# bin/check-template.rb fails the build if this line is deleted.
#
# Lift when a Rails release calls json 3 correctly.
gem "json", "< 3.0"

# The glue: mounts /_cpcp, dispatches the envelope, holds idempotency receipts.
gem "rails-cpcp"

group :development, :test do
  # Executable architecture (Archspec.rb). Static analysis; never boots the app.
  gem "archspec", require: false
end
