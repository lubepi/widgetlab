module DataSources
  module Configs
    # Konfiguration für JSON API Datenquellen
    class JsonApi < Base
      # Erforderliche Felder
      attr_reader :url

      # Optionale Felder mit Defaults
      attr_reader :method, :headers, :query_params, :body, :timeout, :interval
      attr_reader :json_path, :auth, :bearer_token

      def initialize(config_hash = {})
        @config_hash = config_hash.with_indifferent_access

        # Erforderlich
        @url = @config_hash[:url]
        if @url.is_a?(String)
          @url = @url.strip.gsub(/\s+/, "")
          @config_hash[:url] = @url
        end

        # Optional mit Defaults
        @method = @config_hash[:method] || "get"
        @headers = @config_hash[:headers] || {}
        @query_params = @config_hash[:query_params] || {}
        @body = @config_hash[:body]
        @timeout = coerce_numeric(@config_hash[:timeout], default: 30)
        @interval = coerce_numeric(@config_hash[:interval], default: 60)
        @config_hash[:timeout] = @timeout
        @config_hash[:interval] = @interval
        @json_path = @config_hash[:json_path]
        @auth = @config_hash[:auth]
        if @auth.is_a?(Hash)
          @auth = @auth.with_indifferent_access
          if @auth[:username].blank? && @auth[:password].blank?
            @auth = nil
            @config_hash.delete(:auth)
          else
            @config_hash[:auth] = @auth
          end
        end
        @bearer_token = @config_hash[:bearer_token]

        validate!
      end

      # Builder-Pattern für einfache Erstellung
      def self.build
        builder = Builder.new
        yield(builder) if block_given?
        new(builder.to_h)
      end

      # Gibt die vollständige Config als Hash zurück
      def to_h
        {
          url: @url,
          method: @method,
          headers: @headers,
          query_params: @query_params,
          body: @body,
          timeout: @timeout,
          interval: @interval,
          json_path: @json_path,
          auth: @auth,
          bearer_token: @bearer_token
        }.compact
      end

      private

      def coerce_numeric(value, default:)
        return default if value.nil?

        return value if value.is_a?(Numeric)
        return value.to_i if defined?(ActiveSupport::Duration) && value.is_a?(ActiveSupport::Duration)

        if value.is_a?(String)
          stripped = value.strip
          return default if stripped.empty?
          return Integer(stripped) if stripped.match?(/\A-?\d+\z/)
          return Float(stripped) if stripped.match?(/\A-?\d+(?:\.\d+)?\z/)
        end

        raise ArgumentError, "timeout must be of type Integer or Numeric"
      end

      def validate!
        super

        # URL ist erforderlich
        require_field(:url, "URL is required for JSON API data source")

        # Validiere HTTP Methode
        validate_inclusion(:method, %w[get post put patch delete])

        # Validiere Typen
        validate_type(:headers, Hash) if @config_hash[:headers].present?
        validate_type(:query_params, Hash) if @config_hash[:query_params].present?
        validate_type(:timeout, Integer, Numeric) if @config_hash[:timeout].present?
        validate_type(:interval, Integer, Numeric) if @config_hash[:interval].present?

        # Validiere Auth
        if @auth.present?
          validate_type(:auth, Hash)
          unless @auth[:username].present? && @auth[:password].present?
            add_error("auth must contain username and password")
            raise ArgumentError, "auth must contain username and password"
          end
        end
      end

      # Builder-Klasse für Fluent API
      class Builder
        def initialize
          @config = {}
        end

        def url(url)
          @config[:url] = url
          self
        end

        def method(method)
          @config[:method] = method
          self
        end

        def get
          method("get")
        end

        def post
          method("post")
        end

        def headers(headers)
          @config[:headers] = headers
          self
        end

        def add_header(key, value)
          @config[:headers] ||= {}
          @config[:headers][key] = value
          self
        end

        def query_params(params)
          @config[:query_params] = params
          self
        end

        def add_query_param(key, value)
          @config[:query_params] ||= {}
          @config[:query_params][key] = value
          self
        end

        def body(body)
          @config[:body] = body
          self
        end

        def timeout(seconds)
          @config[:timeout] = seconds
          self
        end

        def interval(seconds)
          @config[:interval] = seconds
          self
        end

        def json_path(path)
          @config[:json_path] = path
          self
        end

        def basic_auth(username, password)
          @config[:auth] = { username: username, password: password }
          self
        end

        def bearer_token(token)
          @config[:bearer_token] = token
          self
        end

        def to_h
          @config
        end
      end
    end
  end
end

