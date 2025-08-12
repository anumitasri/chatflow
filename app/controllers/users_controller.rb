class UsersController < ApplicationController
  def me
    render json: current_user.slice(:id, :email, :username, :name, :avatar_url)
  end

  def update
    if current_user.update(user_params)
      render json: { ok: true, user: current_user.slice(:id, :email, :username, :name, :avatar_url) }
    else
      render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private
  def user_params
    params.require(:user).permit(:username, :name, :avatar_url)
  end
end
