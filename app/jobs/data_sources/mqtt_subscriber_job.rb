module DataSources
  class MqttSubscriberJob < ApplicationJob
    queue_as :default

    # Mehr Retry-Versuche für MQTT, da es langlebige Verbindungen sind
    retry_on StandardError, wait: 30.seconds, attempts: 10

    # Nicht automatisch bei diesen Fehlern wiederholen
    discard_on ActiveRecord::RecordNotFound

    def perform(data_source_id)
      data_source = DataSource.find(data_source_id)

      unless data_source.mqtt?
        Rails.logger.error("Data source #{data_source_id} is not an MQTT source")
        return
      end

      unless data_source.send(:auto_subscribe?)
        Rails.logger.info("MQTT subscription disabled for data source #{data_source_id} - skipping")
        return
      end

      subscriber = MqttSubscriber.new(data_source)

      data_source.mark_attempt!

      Rails.logger.info("Starting MQTT subscriber for data source #{data_source_id}")

      # Diese Methode blockiert und hört kontinuierlich auf Nachrichten
      # Bei Verbindungsabbruch wird eine Exception geworfen und der Job neu geplant
      subscriber.subscribe

    rescue MQTT::ProtocolException, Errno::ECONNREFUSED, Errno::ETIMEDOUT => e
      begin
        data_source.mark_error!(e.message)
      rescue StandardError
      end
      Rails.logger.error("MQTT connection error for data source #{data_source_id}: #{e.message}")
      raise # Trigger retry
    rescue Interrupt, SignalException => e
      Rails.logger.info("MQTT subscriber for data source #{data_source_id} was interrupted: #{e.message}")
      # Graceful shutdown - nicht erneut planen
    end
  end
end

