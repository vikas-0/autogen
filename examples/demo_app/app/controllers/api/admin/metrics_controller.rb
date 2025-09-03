# frozen_string_literal: true

module Api
  module Admin
    class MetricsController < ApplicationController
      # GET /api/admin/metrics/uptime
      typed :uptime,
            params: nil,
            returns: { status: :string, uptime_seconds: :integer }
      def uptime
        render json: { status: "ok", uptime_seconds: 12_345 }
      end
    end
  end
end
