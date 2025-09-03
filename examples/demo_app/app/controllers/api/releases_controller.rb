# frozen_string_literal: true

class Api::ReleasesController < ApplicationController
  # POST /api/projects/:project_id/releases/:id/deploy
  typed :deploy,
        params: { project_id: :integer, id: :integer },
        returns: { ok: :boolean, release_id: :integer }
  def deploy
    render json: { ok: true, release_id: params[:id].to_i }
  end
end
