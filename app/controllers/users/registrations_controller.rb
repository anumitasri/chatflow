# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  skip_before_action :verify_authenticity_token, only: [:create, :update]
  respond_to :json, :html

  private
  def respond_with(resource, _opts = {})
    if resource.persisted?
      render json: { status: "success", user: resource.slice(:id, :email, :username, :name, :avatar_url) }, status: :created
    else
      render json: { status: "error", errors: resource.errors.full_messages }, status: :unprocessable_entity
    end
  end
end
