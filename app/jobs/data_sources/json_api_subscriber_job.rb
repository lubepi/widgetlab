module DataSources
  class JsonApiSubscriberJob < ApplicationJob
    queue_as :default

    def perform(data_source_id)
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
    rescue ActiveRecord::RecordNotFound
      Rails.logger.error("Data source #{data_source_id} not found")
    rescue StandardError => e
      Rails.logger.error("Error in JsonApiSubscriberJob for data source #{data_source_id}: #{e.message}")
      raise
    end
  end
end

