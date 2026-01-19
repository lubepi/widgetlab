require "json/jwt"

class SessionsController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :new, :create, :failure, :test_create ]

  # Test-only action for creating sessions in tests
  def test_create
    raise "Only available in test environment" unless Rails.env.test?
    
    user = User.find_or_create_by!(sub: params[:sub]) do |u|
      u.email = params[:email]
      u.first_name = params[:first_name]
      u.last_name = params[:last_name]
    end
    
    session[:user_id] = user.id
    session[:locale] = :en  # Use English locale in tests
    head :ok
  end

  def new
    redirect_to "/auth/keycloak"
  end

  def create
    auth_hash = request.env["omniauth.auth"]
    user = find_or_create_user(auth_hash)

    # Nur User-ID in der Session speichern (Tokens sind zu groß für Cookie-Sessions)
    session[:user_id] = user.id
    session[:keycloak_roles] = extract_keycloak_roles(auth_hash)

    redirect_to root_path, notice: t('sessions.flash.signed_in')
  end

  def destroy
    reset_session

    # Keycloak-Logout-URL
    keycloak_logout_url = build_keycloak_logout_url
    redirect_to keycloak_logout_url, allow_other_host: true
  end

  def failure
    redirect_to root_path, alert: t('sessions.flash.auth_failed', message: params[:message])
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

  def extract_keycloak_roles(auth_hash)
    access_token = auth_hash&.credentials&.token
    claims = jwt_claims(access_token)

    if claims.blank?
      raw_info = auth_hash&.extra&.raw_info
      claims = raw_info.respond_to?(:to_h) ? raw_info.to_h : {}
    end

    realm_access = claims["realm_access"] || claims[:realm_access] || {}
    realm_access_hash = realm_access.respond_to?(:to_h) ? realm_access.to_h : {}
    realm_roles = realm_access_hash["roles"] || realm_access_hash[:roles] || []

    groups = claims["groups"] || claims[:groups] || []

    Array(realm_roles).concat(Array(groups)).map(&:to_s).map(&:downcase).uniq
  end

  def jwt_claims(token)
    return {} if token.blank?

    JSON::JWT.decode(token, :skip_verification).to_h
  rescue JSON::JWT::InvalidFormat, JSON::JWS::VerificationFailed, ArgumentError
    {}
  end

  def build_keycloak_logout_url
    base_url = ENV.fetch("KEYCLOAK_ISSUER") { "http://localhost:8080/realms/widgetlab" }
    post_logout_redirect_uri = CGI.escape(root_url)
    client_id = ENV.fetch("KEYCLOAK_CLIENT_ID") { "widgetlab" }

    "#{base_url}/protocol/openid-connect/logout?client_id=#{client_id}&post_logout_redirect_uri=#{post_logout_redirect_uri}"
  end
end
