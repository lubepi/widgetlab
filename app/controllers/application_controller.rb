class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # Authentifizierung für alle Controller
  before_action :authenticate_user!

  helper_method :current_user, :user_signed_in?, :keycloak_roles, :has_role?, :admin?

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def user_signed_in?
    current_user.present?
  end

  def keycloak_roles
    Array(session[:keycloak_roles]).map(&:to_s).map(&:downcase).uniq
  end

  def has_role?(role)
    keycloak_roles.include?(role.to_s.downcase)
  end

  def admin?
    has_role?("admin")
  end

  def authenticate_user!
    unless user_signed_in?
      respond_to do |format|
        format.html { redirect_to login_path, alert: "Bitte melde dich an, um fortzufahren." }
        format.json { render json: { error: "Nicht authentifiziert" }, status: :unauthorized }
      end
    end
  end
end
