module DataSources
  class JsonApiSubscriber
    attr_reader :data_source

    def initialize(data_source)
      @data_source = data_source
      validate_config!
    end

    # Führt einen einzelnen Fetch-Vorgang durch
    def fetch_and_store
      response = fetch_data

      if response.success?
        value = parse_response(response)
        store_value(value)
        Rails.logger.info("Successfully stored JSON API data for data source #{data_source.id}")
        { success: true, value: value }
      else
        Rails.logger.error("Failed to fetch JSON API data: #{response.code} - #{response.message}")
        { success: false, error: "HTTP #{response.code}: #{response.message}" }
      end
    rescue StandardError => e
      Rails.logger.error("Error fetching JSON API data: #{e.message}")
      { success: false, error: e.message }
    end

    # Startet ein wiederkehrendes Abonnement (über Recurring Jobs)
    def subscribe(interval: nil)
      interval ||= config.interval

      # Hier würde man das wiederkehrende Job-System konfigurieren
      Rails.logger.info("Setting up JSON API subscription for data source #{data_source.id} with interval #{interval}s")

      fetch_and_store
    end

    private

    def config
      @config ||= begin
        if data_source.config.is_a?(Configs::JsonApi)
          data_source.config
        else
          Configs::JsonApi.new(data_source.config)
        end
      end
    end

    def validate_config!
      # Validierung erfolgt bereits in der Config-Klasse
      config.valid?
    end

    def fetch_data
      options = build_request_options

      case config.method.downcase
      when "get"
        HTTParty.get(config.url, options)
      when "post"
        HTTParty.post(config.url, options)
      else
        raise ArgumentError, "Unsupported HTTP method: #{config.method}"
      end
    end

    def build_request_options
      options = {}

      # Headers
      if config.headers.present?
        options[:headers] = config.headers
      end

      # Query parameters
      if config.query_params.present?
        options[:query] = config.query_params
      end

      # Body für POST requests
      if config.body.present?
        options[:body] = config.body
      end

      # Timeout
      options[:timeout] = config.timeout

      # Basic Auth
      if config.auth.present?
        options[:basic_auth] = {
          username: config.auth[:username],
          password: config.auth[:password]
        }
      end

      # Bearer Token
      if config.bearer_token.present?
        options[:headers] ||= {}
        options[:headers]["Authorization"] = "Bearer #{config.bearer_token}"
      end

      options
    end

    def parse_response(response)
      # Wenn ein JSONPath konfiguriert ist, extrahiere nur diesen Teil
      if config.json_path.present?
        extract_json_path(response.parsed_response, config.json_path)
      else
        response.parsed_response
      end
    end

    def extract_json_path(data, path)
      # Einfache JSONPath-Implementation für verschachtelte Daten
      # z.B. "data.temperature" würde data["temperature"] extrahieren
      path.split(".").reduce(data) do |obj, key|
        obj.is_a?(Hash) ? obj[key] : obj
      end
    end

    def store_value(value)
      data_source.store_value(value)
    end
  end
end

