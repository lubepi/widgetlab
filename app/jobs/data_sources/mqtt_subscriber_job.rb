module DataSources
  class MqttSubscriberJob < ApplicationJob
    queue_as :default

    def perform(data_source_id)
      data_source = DataSource.find(data_source_id)

      unless data_source.mqtt?
        Rails.logger.error("Data source #{data_source_id} is not an MQTT source")
        return
      end

      subscriber = MqttSubscriber.new(data_source)

      Rails.logger.info("Starting MQTT subscriber for data source #{data_source_id}")
      subscriber.subscribe

    rescue ActiveRecord::RecordNotFound
      Rails.logger.error("Data source #{data_source_id} not found")
    rescue StandardError => e
      Rails.logger.error("Error in MqttSubscriberJob for data source #{data_source_id}: #{e.message}")
      # Bei Fehler automatisch nach 30 Sekunden neu versuchen
      retry_job wait: 30.seconds, queue: :default
    end
  end
end

