module DataSources
  class JsonApiSubscriberJob < ApplicationJob
    queue_as :default

    # Automatische Retry-Logik bei Fehlern
    retry_on StandardError, wait: :polynomially_longer, attempts: 3

    def perform(data_source_id, reschedule: true)
      data_source = DataSource.find(data_source_id)

      unless data_source.json_api?
        Rails.logger.error("Data source #{data_source_id} is not a JSON API source")
        return
      end

      subscriber = JsonApiSubscriber.new(data_source)
      result = subscriber.fetch_and_store

      unless result[:success]
        Rails.logger.error("Failed to fetch JSON API data for data source #{data_source_id}: #{result[:error]}")
      end

      # Plane den nächsten Fetch basierend auf dem konfigurierten Intervall
      if reschedule
        schedule_next_fetch(data_source)
      end
    rescue ActiveRecord::RecordNotFound
      Rails.logger.error("Data source #{data_source_id} not found - stopping recurring job")
      # Nicht erneut planen wenn DataSource nicht mehr existiert
    end

    private

    def schedule_next_fetch(data_source)
      interval = data_source.typed_config.interval
      self.class.set(wait: interval.seconds).perform_later(data_source.id, reschedule: true)
      Rails.logger.debug("Scheduled next JSON API fetch for data source #{data_source.id} in #{interval}s")
    end
  end
end

