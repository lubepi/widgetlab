# Keycloak-Basis-URL
keycloak_base_url = ENV.fetch("KEYCLOAK_ISSUER") { "http://localhost:8080/realms/widgetlab" }

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :openid_connect, {
    name: :keycloak,
    scope: [ :openid, :email, :profile ],
    response_type: :code,
    issuer: keycloak_base_url,
    # Discovery deaktivieren und Endpoints manuell definieren
    # um SSL-Upgrade bei HTTP-URLs zu vermeiden
    discovery: false,
    client_options: {
      site: keycloak_base_url,
      authorization_endpoint: "#{keycloak_base_url}/protocol/openid-connect/auth",
      token_endpoint: "#{keycloak_base_url}/protocol/openid-connect/token",
      userinfo_endpoint: "#{keycloak_base_url}/protocol/openid-connect/userinfo",
      jwks_uri: "#{keycloak_base_url}/protocol/openid-connect/certs",
      identifier: ENV.fetch("KEYCLOAK_CLIENT_ID") { "widgetlab" },
      secret: ENV.fetch("KEYCLOAK_CLIENT_SECRET", nil),
      redirect_uri: ENV.fetch("KEYCLOAK_REDIRECT_URI") { "http://localhost:3000/auth/keycloak/callback" }
    },
    pkce: true
  }
end

# Konfiguration für OmniAuth
OmniAuth.config.logger = Rails.logger
OmniAuth.config.allowed_request_methods = [ :post, :get ]
OmniAuth.config.silence_get_warning = true
