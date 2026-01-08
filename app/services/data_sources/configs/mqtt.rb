module DataSources
  module Configs
    # Konfiguration für MQTT Datenquellen
    class Mqtt < Base
      # Erforderliche Felder
      attr_reader :host, :topic

      # Optionale Felder mit Defaults
      attr_reader :port, :username, :password, :client_id, :clean_session
      attr_reader :keep_alive, :qos, :parse_json
      attr_reader :use_ssl, :ca_file, :cert_file, :key_file

      def initialize(config_hash = {})
        @config_hash = config_hash.with_indifferent_access

        # Erforderlich
        @host = @config_hash[:host]
        @topic = @config_hash[:topic]

        # Optional mit Defaults
        @port = @config_hash[:port] || 1883
        @username = @config_hash[:username]
        @password = @config_hash[:password]
        @client_id = @config_hash[:client_id]
        @clean_session = @config_hash.key?(:clean_session) ? @config_hash[:clean_session] : true
        @keep_alive = @config_hash[:keep_alive] || 15
        @qos = @config_hash[:qos] || 0
        @parse_json = @config_hash.key?(:parse_json) ? @config_hash[:parse_json] : true

        # SSL/TLS
        @use_ssl = @config_hash[:use_ssl] || false
        @ca_file = @config_hash[:ca_file]
        @cert_file = @config_hash[:cert_file]
        @key_file = @config_hash[:key_file]

        validate!
      end

      # Builder-Pattern für einfache Erstellung
      def self.build
        builder = Builder.new
        yield(builder) if block_given?
        new(builder.to_h)
      end

      # Gibt Topics als Array zurück (auch wenn nur ein String)
      def topics
        Array(@topic)
      end

      # Gibt die vollständige Config als Hash zurück
      def to_h
        {
          host: @host,
          port: @port,
          topic: @topic,
          username: @username,
          password: @password,
          client_id: @client_id,
          clean_session: @clean_session,
          keep_alive: @keep_alive,
          qos: @qos,
          parse_json: @parse_json,
          use_ssl: @use_ssl,
          ca_file: @ca_file,
          cert_file: @cert_file,
          key_file: @key_file
        }.compact
      end

      private

      def validate!
        super

        # Host und Topic sind erforderlich
        require_field(:host, "MQTT host is required")
        require_field(:topic, "MQTT topic is required")

        # Validiere Port
        if @port.present?
          validate_type(:port, Integer, Numeric)
          if @port < 1 || @port > 65535
            add_error("port must be between 1 and 65535")
            raise ArgumentError, "port must be between 1 and 65535"
          end
        end

        # Validiere QoS
        validate_inclusion(:qos, [0, 1, 2]) if @config_hash[:qos].present?

        # Validiere Keep Alive
        validate_type(:keep_alive, Integer, Numeric) if @config_hash[:keep_alive].present?

        # Validiere Boolean Felder
        validate_type(:clean_session, TrueClass, FalseClass) if @config_hash.key?(:clean_session)
        validate_type(:parse_json, TrueClass, FalseClass) if @config_hash.key?(:parse_json)
        validate_type(:use_ssl, TrueClass, FalseClass) if @config_hash.key?(:use_ssl)

        # Validiere Topic Format (String oder Array)
        unless @topic.is_a?(String) || @topic.is_a?(Array)
          add_error("topic must be a String or Array")
          raise ArgumentError, "topic must be a String or Array"
        end
      end

      class Builder
        def initialize
          @config = {}
        end

        def host(host)
          @config[:host] = host
          self
        end

        def port(port)
          @config[:port] = port
          self
        end

        def topic(topic)
          @config[:topic] = topic
          self
        end

        def topics(*topics)
          @config[:topic] = topics.flatten
          self
        end

        def username(username)
          @config[:username] = username
          self
        end

        def password(password)
          @config[:password] = password
          self
        end

        def credentials(username, password)
          @config[:username] = username
          @config[:password] = password
          self
        end

        def client_id(client_id)
          @config[:client_id] = client_id
          self
        end

        def clean_session(enabled = true)
          @config[:clean_session] = enabled
          self
        end

        def keep_alive(seconds)
          @config[:keep_alive] = seconds
          self
        end

        def qos(level)
          @config[:qos] = level
          self
        end

        def parse_json(enabled = true)
          @config[:parse_json] = enabled
          self
        end

        def ssl(enabled = true)
          @config[:use_ssl] = enabled
          self
        end

        def ca_file(path)
          @config[:ca_file] = path
          self
        end

        def cert_file(path)
          @config[:cert_file] = path
          self
        end

        def key_file(path)
          @config[:key_file] = path
          self
        end

        def ssl_files(ca:, cert: nil, key: nil)
          @config[:ca_file] = ca
          @config[:cert_file] = cert if cert
          @config[:key_file] = key if key
          self
        end

        def to_h
          @config
        end
      end
    end
  end
end

