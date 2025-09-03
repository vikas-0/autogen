# frozen_string_literal: true

require 'securerandom'

class Api::ReportsController < ApplicationController
  # GET /api/reports/:year/:month
  typed :monthly,
        params: { year: :integer, month: :integer },
        returns: { year: :integer, month: :integer, total: :integer }
  def monthly
    render json: { year: params[:year].to_i, month: params[:month].to_i, total: 42 }
  end

  # POST /api/reports/run
  typed :run,
        params: { kind?: :string },
        returns: { job_id: :string }
  def run
    render json: { job_id: "job_#{SecureRandom.hex(4)}" }
  end
end
