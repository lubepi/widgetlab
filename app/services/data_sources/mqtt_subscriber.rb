module DataSources
  class MqttSubscriber
    attr_reader :data_source, :client

    def initialize(data_source)
      @data_source = data_source
      @client = nil
      validate_config!
    end

    # Startet das MQTT Abonnement
    def subscribe
      connect_to_broker
      subscribe_to_topics
      listen_for_messages
    rescue StandardError => e
      begin
        data_source.mark_error!(e.message)
      rescue StandardError
      end
      Rails.logger.error("Error in MQTT subscription: #{e.message}")
      disconnect
      raise
    end

    # Stoppt das MQTT Abonnement
    def unsubscribe
      disconnect
    end

    # Verbindet zum MQTT Broker (ohne zu abonnieren)
    def connect
      connect_to_broker
    end

    # Überprüft die Verbindung
    def connected?
      @client&.connected?
    end

    private

    def config
      @config ||= begin
        if data_source.config.is_a?(Configs::Mqtt)
          data_source.config
        else
          Configs::Mqtt.new(data_source.config)
        end
      end
    end

    def validate_config!
      # Validierung erfolgt bereits in der Config-Klasse
      config.valid?
    end

    def connect_to_broker
      @client = MQTT::Client.new(
        host: config.host,
        port: config.port,
        username: config.username,
        password: config.password,
        client_id: config.client_id || "widgetlab_#{data_source.id}_#{SecureRandom.hex(4)}",
        clean_session: config.clean_session,
        keep_alive: config.keep_alive
      )

      # SSL/TLS Konfiguration
      if config.use_ssl
        @client.ssl = true
        @client.cert_file = config.cert_file if config.cert_file.present?
        @client.key_file = config.key_file if config.key_file.present?
        @client.ca_file = config.ca_file if config.ca_file.present?
      end

      @client.connect
      data_source.update(status: :inactive, last_error: nil)
      Rails.logger.info("Connected to MQTT broker at #{config.host}:#{config.port}")
    rescue StandardError => e
      begin
        data_source.mark_error!(e.message)
      rescue StandardError
      end
      Rails.logger.error("Failed to connect to MQTT broker: #{e.message}")
      raise
    end

    def subscribe_to_topics
      topics = config.topics
      qos = config.qos

      topics.each do |topic|
        @client.subscribe(topic, qos)
        Rails.logger.info("Subscribed to MQTT topic: #{topic} (QoS: #{qos})")
      end
    end

    def listen_for_messages
      @client.get do |topic, message|
        break unless data_source.reload.send(:auto_subscribe?)

        process_message(topic, message)
      end

      disconnect
    end

    def process_message(topic, message)
      Rails.logger.debug("Received MQTT message on topic #{topic}: #{message}")

      value = parse_message(message)
      store_value(value, topic)

      data_source.mark_success!

      Rails.logger.info("Stored MQTT message from topic #{topic} for data source #{data_source.id}")
    rescue StandardError => e
      begin
        data_source.mark_error!(e.message)
      rescue StandardError
      end
      Rails.logger.error("Error processing MQTT message: #{e.message}")
    end

    def parse_message(message)
      # Versuche als JSON zu parsen, falls konfiguriert oder möglich
      if config.parse_json
        begin
          JSON.parse(message)
        rescue JSON::ParserError
          # Falls kein JSON, gib den Rohwert zurück
          { raw: message }
        end
      else
        { raw: message }
      end
    end

    def store_value(value, topic)
      # Füge das Topic zur gespeicherten Value hinzu
      enriched_value = {
        data: value,
        topic: topic
      }

      data_source.store_value(enriched_value)
    end

    def disconnect
      if @client&.connected?
        @client.disconnect
        Rails.logger.info("Disconnected from MQTT broker for data source #{data_source.id}")
      end
    rescue StandardError => e
      Rails.logger.error("Error disconnecting from MQTT broker: #{e.message}")
    end
  end
end

