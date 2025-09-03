# frozen_string_literal: true

class Api::UsersController < ApplicationController
  # Explicit DSL declaration for create
  typed :create,
        params: { user: { name: :string, email: :string } },
        returns: { id: :integer, name: :string, email: :string, created_at: :datetime }

  def index
    users = User.all
    render json: users
  end

  typed :show,
        params: { id: :integer },
        returns: { id: :integer, name: :string, email: :string, created_at: :datetime }

  def show
    user = User.find(params[:id])
    render json: user
  end

  def create
    user = User.create!(user_params)
    render json: user
  end

  private

  def user_params
    params.require(:user).permit(:name, :email)
  end
end
