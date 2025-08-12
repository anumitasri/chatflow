# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  skip_before_action :verify_authenticity_token, only: [:create, :destroy]
  respond_to :json, :html

  private
  def respond_with(resource, _opts = {})
    render json: { status: "success", user: resource.slice(:id, :email, :username, :name, :avatar_url) }, status: :ok
  end

  def respond_to_on_destroy
    head :no_content
  end
end
