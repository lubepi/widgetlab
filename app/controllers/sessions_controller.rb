class SessionsController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :new, :create, :failure ]

  def new
    redirect_to "/auth/keycloak"
  end

  def create
    auth_hash = request.env["omniauth.auth"]
    user = find_or_create_user(auth_hash)

    # Nur User-ID in der Session speichern (Tokens sind zu groß für Cookie-Sessions)
    session[:user_id] = user.id

    redirect_to root_path, notice: "Erfolgreich angemeldet!"
  end

  def destroy
    reset_session

    # Keycloak-Logout-URL
    keycloak_logout_url = build_keycloak_logout_url
    redirect_to keycloak_logout_url, allow_other_host: true
  end

  def failure
    redirect_to root_path, alert: "Authentifizierung fehlgeschlagen: #{params[:message]}"
  end

  private

  def find_or_create_user(auth_hash)
    User.find_or_create_by(sub: auth_hash.uid) do |user|
      user.email = auth_hash.info.email
      user.first_name = auth_hash.info.first_name || auth_hash.info.given_name
      user.last_name = auth_hash.info.last_name || auth_hash.info.family_name
    end.tap do |user|
      # Aktualisiere Benutzerdaten bei jedem Login
      user.update(
        email: auth_hash.info.email,
        first_name: auth_hash.info.first_name || auth_hash.info.given_name,
        last_name: auth_hash.info.last_name || auth_hash.info.family_name
      )
    end
  end

  def build_keycloak_logout_url
    base_url = ENV.fetch("KEYCLOAK_ISSUER") { "http://localhost:8080/realms/widgetlab" }
    post_logout_redirect_uri = CGI.escape(root_url)
    client_id = ENV.fetch("KEYCLOAK_CLIENT_ID") { "widgetlab" }

    "#{base_url}/protocol/openid-connect/logout?client_id=#{client_id}&post_logout_redirect_uri=#{post_logout_redirect_uri}"
  end
end
