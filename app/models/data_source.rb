class DataSource < ApplicationRecord
  belongs_to :creator, class_name: "User", foreign_key: "creator_id"

  has_many :widget_data_source_transformers, dependent: :destroy
  has_many :widgets, through: :widget_data_source_transformers
  has_many :data_source_storages, dependent: :destroy

  # Enum für die verschiedenen Datenquellentypen
  enum :source_type, { json_api: 0, mqtt: 1 }

  validates :name, presence: true
  validates :source_type, presence: true
  validates :config, presence: true

  # Gibt die Config als typisiertes Objekt zurück
  def typed_config
    case source_type.to_sym
    when :json_api
      DataSources::Configs::JsonApi.new(config)
    when :mqtt
      DataSources::Configs::Mqtt.new(config)
    else
      raise ArgumentError, "Unknown source type: #{source_type}"
    end
  end

  # Hilfsmethode zum Speichern neuer Werte
  def store_value(value, stored_at: Time.current)
    data_source_storages.create!(value: value, stored_at: stored_at)
  end

  # Hilfsmethode zum Abrufen der neuesten Werte
  def latest_values(limit: 10)
    data_source_storages.recent.limit(limit)
  end

  # Hilfsmethode zum Abrufen des letzten gespeicherten Werts
  def latest_value
    data_source_storages.recent.first
  end
end
