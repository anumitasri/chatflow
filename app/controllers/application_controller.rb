class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  protect_from_forgery with: :null_session
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?
  respond_to :json, :html

  rescue_from ActiveRecord::RecordNotFound do
    render json: { error: "Not found" }, status: :not_found
  end

  def render_validation_errors!(record)
    render json: { errors: record.errors.full_messages }, status: :unprocessable_entity
  end

  protected
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up,        keys: %i[username name avatar_url])
    devise_parameter_sanitizer.permit(:account_update, keys: %i[username name avatar_url])
  end
end
