#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Does a copy of this template still conform?
#
# Runs BESIDE the contract's check-repo-format.py, not instead of it. The format
# checker holds the .cpcp manifests; this holds everything the template claims
# that is not a manifest -- the layout, the CPCP wiring, and the one thing only
# a live check can settle: that the reference instance actually serves what the
# manifest says it serves.
#
# Ruby with no gems, because a template's validator that needs `bundle install`
# is a validator that gets skipped on the day it would have caught something.
#
# Usage:  ruby bin/check-template.rb [--offline]
#         --offline  skip the live reference check, and SAY it was skipped

require "json"
require "net/http"
require "uri"

ROOT = File.expand_path("..", __dir__)
OFFLINE = ARGV.include?("--offline")

@failures = []
@notes = []

def fail!(message) = @failures << message
def note(message)  = @notes << message

# ---------------------------------------------------------------- structure

MANIFEST_PATH = File.join(ROOT, ".cpcp", "package.json")

unless File.file?(MANIFEST_PATH)
  abort "TEMPLATE FAIL: .cpcp/package.json is missing; there is nothing to check against"
end

manifest = begin
  JSON.parse(File.read(MANIFEST_PATH))
rescue JSON::ParserError => e
  abort "TEMPLATE FAIL: .cpcp/package.json does not parse: #{e.message}"
end

# The manifest names the files this template promises. Reading the list from
# the manifest rather than hardcoding it here means the promise and the check
# cannot drift: change one and the other follows.
required = manifest.dig("layout", "required") || []
if required.empty?
  fail! "layout.required is empty; the template promises no files, so this checks nothing"
end
required.each do |rel|
  fail!("#{rel} is promised by layout.required and does not exist") unless File.exist?(File.join(ROOT, rel))
end
note "#{required.size} promised path(s)"

# Rails at root. A copy that moved these has stopped being the thing a Ruby
# developer recognises, which is the whole reason for the layout choice.
%w[app config bin].each do |dir|
  fail!("#{dir}/ is missing: this template is Rails AT ROOT") unless File.directory?(File.join(ROOT, dir))
end

# ---------------------------------------------------------------- CPCP wiring

routes = File.join(ROOT, "config", "routes.rb")
if File.file?(routes)
  src = File.read(routes)
  unless src.match?(/mount\s+RailsCpcp::Engine\s*=>/)
    fail! "config/routes.rb does not mount RailsCpcp::Engine; a BACK without the seam mounted " \
          "serves no CPCP surface at all"
  end
  # The three roles are the deploy. A route table that does not branch on ROLE
  # describes one process, and the compose file describing three would be
  # deploying the same surface three times.
  unless src.include?("ROLE")
    fail! "config/routes.rb never reads ROLE; this template is one image and three roles, " \
          "and the route table is where they diverge"
  end
  %w[back front backjob].each do |role|
    fail!("config/routes.rb draws no #{role} role") unless src.include?(%("#{role}"))
  end
end

# FRONT must have a way to reach BACK that is not a model. If the base
# controller went missing, every Front:: controller would inherit from
# ActionController::Base and the only remaining route to data would be the one
# Archspec forbids.
front_base = File.join(ROOT, "app", "controllers", "front", "base_controller.rb")
if File.file?(front_base)
  src = File.read(front_base)
  fail!("Front::BaseController offers no pull") unless src.include?("def pull")
  fail!("Front::BaseController offers no push") unless src.include?("def push")
  unless src.match?(/BACK_CPCP_ORIGIN/)
    fail! "Front::BaseController does not read BACK_CPCP_ORIGIN; FRONT has to be told where " \
          "BACK is, and hardcoding it makes the split undeployable"
  end
end

projection = File.join(ROOT, "config", "initializers", "rails_cpcp.rb")
if File.file?(projection)
  src = File.read(projection)
  fail!("the projection declares no operation") unless src.include?("operation ")
  # ArchSpec forbids app code naming RailsCpcp; the projection is the one place
  # that may. If the projection ALSO stopped naming it, the seam is unwired.
  fail!("the projection never names RailsCpcp") unless src.include?("RailsCpcp")
end

# ---------------------------------------------------------------- the live half

ref = manifest["reference_instance"]
if ref.nil?
  fail! "no reference_instance: rule 10 says a template must resolve to a running service"
else
  cid_url  = ref["cid"].to_s
  claimed  = Array(ref["operations"])
  liveness = ref["liveness"].to_s

  if OFFLINE
    # Skipping is allowed; skipping SILENTLY is not. A run that did not check
    # the live half must not read like one that did.
    note "reference instance NOT CHECKED (--offline). #{claimed.size} claimed operation(s) unverified."
  else
    begin
      uri = URI.parse(cid_url)
      res = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
                            open_timeout: 10, read_timeout: 10) do |http|
        http.get(uri.request_uri)
      end

      if res.code.to_i != 200
        message = "reference_instance #{cid_url} answered HTTP #{res.code}"
        liveness == "advisory" ? note("#{message} (advisory: #{ref['because']})") : fail!(message)
      else
        doc = JSON.parse(res.body)
        published = Array(doc["operations"]).map { |o| o["name"] }.compact
        missing = claimed - published
        if missing.empty?
          note "reference instance live: #{cid_url} publishes #{published.size} operation(s), " \
               "including all #{claimed.size} claimed"
        else
          # This is the check that makes rule 10 more than a formatting rule.
          fail! "reference_instance claims #{missing.inspect} but #{cid_url} publishes " \
                "#{published.inspect}. The template describes endpoints the service does not serve."
        end
      end
    rescue StandardError => e
      message = "reference_instance #{cid_url} unreachable: #{e.class}: #{e.message}"
      if liveness == "advisory"
        note "#{message} (advisory: #{ref['because']})"
      else
        # liveness: required means an outage is a failure. A template pointing
        # at something that is not there is the defect rule 10 names.
        fail! message
      end
    end
  end
end

# ---------------------------------------------------------------- report

@notes.each { |n| puts "  #{n}" }
if @failures.empty?
  puts "template: OK"
  exit 0
end
warn "TEMPLATE FAIL (#{@failures.size})"
@failures.each { |f| warn "  #{f}" }
exit 1
