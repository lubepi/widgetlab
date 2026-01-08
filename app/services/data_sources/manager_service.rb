module DataSources
  class ManagerService
    attr_reader :data_source

    # Erstellt eine neue Datenquelle und startet optional das Abonnement
    # config kann entweder ein Hash oder eine Config-Klasse sein
    def self.create_and_subscribe(creator:, name:, source_type:, config:, is_public: false, auto_subscribe: true)
      new.create_and_subscribe(
        creator: creator,
        name: name,
        source_type: source_type,
        config: config,
        is_public: is_public,
        auto_subscribe: auto_subscribe
      )
    end

    def create_and_subscribe(creator:, name:, source_type:, config:, is_public: false, auto_subscribe: true)
      # Konvertiere Config-Objekt zu Hash wenn nötig
      config_hash = config.is_a?(Configs::Base) ? config.to_h : config

      @data_source = DataSource.create!(
        creator: creator,
        name: name,
        source_type: source_type,
        config: config_hash,
        is_public: is_public
      )

      subscribe if auto_subscribe

      @data_source
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error("Failed to create data source: #{e.message}")
      raise
    end

    # Abonniert eine existierende Datenquelle
    def self.subscribe(data_source)
      new(data_source).subscribe
    end

    def initialize(data_source = nil)
      @data_source = data_source
    end

    def subscribe
      raise ArgumentError, "Data source not set" unless @data_source

      case @data_source.source_type.to_sym
      when :json_api
        subscribe_json_api
      when :mqtt
        subscribe_mqtt
      else
        raise ArgumentError, "Unknown source type: #{@data_source.source_type}"
      end
    end

    # Stoppt das Abonnement einer Datenquelle
    def self.unsubscribe(data_source)
      new(data_source).unsubscribe
    end

    def unsubscribe
      raise ArgumentError, "Data source not set" unless @data_source

      case @data_source.source_type.to_sym
      when :json_api
        unsubscribe_json_api
      when :mqtt
        unsubscribe_mqtt
      else
        raise ArgumentError, "Unknown source type: #{@data_source.source_type}"
      end
    end

    private

    def subscribe_json_api
      DataSources::JsonApiSubscriberJob.perform_later(@data_source.id)
      Rails.logger.info("Scheduled JSON API subscription for data source #{@data_source.id}")
    end

    def subscribe_mqtt
      DataSources::MqttSubscriberJob.perform_later(@data_source.id)
      Rails.logger.info("Scheduled MQTT subscription for data source #{@data_source.id}")
    end

    def unsubscribe_json_api
      # JSON API Abonnements werden über wiederkehrende Jobs gesteuert
      Rails.logger.info("JSON API subscription for data source #{@data_source.id} will stop naturally")
    end

    def unsubscribe_mqtt
      # MQTT Abonnements müssen explizit gestoppt werden
      # Dies würde über ein separates System verwaltet werden
      Rails.logger.info("MQTT subscription stop requested for data source #{@data_source.id}")
    end
  end
end

