# frozen_string_literal: true

# FRONT's base: everything a UI controller needs, and nothing that touches
# domain state.
#
# THE ONE RULE THIS ENFORCES AT RUNTIME. FRONT reaches BACK over CPCP and only
# over CPCP. There is no ActiveRecord here, no model constant, no database
# connection -- Archspec.rb holds that statically, and this class holds it by
# not offering an alternative: `seam` is the only way out of FRONT.
module Front
  class BaseController < ActionController::Base
    private

    # The BACK this FRONT talks to. In the pod it is a container name; in
    # development it is the other process on loopback.
    def back_origin
      ENV.fetch("BACK_CPCP_ORIGIN", "http://127.0.0.1:3000/_cpcp")
    end

    # A PULL: read. Costs nothing, promises nothing, needs no operationId.
    def pull(method, params = {})
      RailsCpcp::Client.pull(back_origin, method, params)
    end

    # A PUSH: write. NAMES ITS INTENT BEFORE PERFORMING IT.
    #
    # Generate the operationId ONCE per intent -- here, per user action -- and
    # reuse it across retries. A fresh id per attempt is an idempotency key that
    # idempotates nothing, which is the failure that makes "just retry it"
    # unsafe for anything but reads.
    def push(method, params = {}, operation_id: nil)
      RailsCpcp::Client.push(back_origin, method, params,
                             operation_id || "#{controller_name}-#{action_name}-#{SecureRandom.uuid}")
    end

    # Every answer is an envelope: { ok: true, ... } or { ok: false, reason:,
    # because: }. Nothing raises across the seam, so a view has one failure
    # path to render rather than a rescue per call.
    def render_envelope(envelope, ok_status: :ok)
      if envelope[:ok] || envelope["ok"]
        render json: envelope, status: ok_status
      else
        render json: envelope, status: :bad_gateway
      end
    end
  end
end
