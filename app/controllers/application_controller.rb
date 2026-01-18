class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # i18n: Locale aus der Session oder dem Browser setzen
  before_action :set_locale

  # Authentifizierung für alle Controller
  before_action :authenticate_user!

  helper_method :current_user, :user_signed_in?, :keycloak_roles, :has_role?, :admin?

  private

  def set_locale
    I18n.locale = session[:locale] || extract_locale_from_accept_language_header || I18n.default_locale
  end

  def extract_locale_from_accept_language_header
    return nil unless request.env['HTTP_ACCEPT_LANGUAGE']
    
    accepted = request.env['HTTP_ACCEPT_LANGUAGE'].scan(/[a-z]{2}/).first&.to_sym
    I18n.available_locales.include?(accepted) ? accepted : nil
  end

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
        format.html { redirect_to login_path, alert: t('sessions.flash.please_sign_in') }
        format.json { render json: { error: t('sessions.flash.not_authenticated') }, status: :unauthorized }
      end
    end
  end
end
