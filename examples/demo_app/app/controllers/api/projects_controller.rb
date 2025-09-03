# frozen_string_literal: true

class Api::ProjectsController < ApplicationController
  # GET /api/projects/:id/summary
  typed :summary,
        params: { id: :integer },
        returns: { id: :integer, name: :string, summary: :string }
  def summary
    render json: { id: params[:id].to_i, name: "Demo Project", summary: "A short summary." }
  end

  # POST /api/projects/:id/archive
  typed :archive,
        params: { id: :integer },
        returns: { ok: :boolean }
  def archive
    render json: { ok: true }
  end

  # GET /api/projects/search?q=...
  typed :search,
        params: { q?: :string },
        returns: [{ id: :integer, name: :string }]
  def search
    results = [ { id: 1, name: "Alpha" }, { id: 2, name: "Beta" } ]
    render json: results
  end
end
