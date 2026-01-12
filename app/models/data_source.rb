class DataSource < ApplicationRecord
  belongs_to :creator, class_name: "User", foreign_key: "creator_id"

  has_many :widget_data_source_transformers, dependent: :destroy
  has_many :widgets, through: :widget_data_source_transformers
  has_many :data_source_storages, dependent: :destroy
  has_many :data_source_whitelists, dependent: :destroy

  # Enum für die verschiedenen Datenquellentypen
  enum :source_type, { json_api: 0, mqtt: 1 }

  enum :status, { inactive: 0, ok: 1, error: 2 }

  validates :name, presence: true
  validates :source_type, presence: true
  validates :config, presence: true

  def self.accessible_for(user)
    return where(is_public: true) if user.blank?

    group_ids = user.user_groups.select(:id)

    left_outer_joins(:data_source_whitelists)
      .where(
        "data_sources.is_public = TRUE OR (data_sources.is_public IS DISTINCT FROM TRUE AND ((data_source_whitelists.whitelistable_type = 'User' AND data_source_whitelists.whitelistable_id = ?) OR (data_source_whitelists.whitelistable_type = 'UserGroup' AND data_source_whitelists.whitelistable_id IN (?))))",
        user.id,
        group_ids
      )
      .distinct
  end

  # Callbacks
  after_create :start_subscription, if: :auto_subscribe?
  before_destroy :stop_subscription

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

  # Startet das Abonnement für diese Datenquelle
  def start_subscription
    DataSources::ManagerService.subscribe(self)
  end

  # Stoppt das Abonnement für diese Datenquelle
  def stop_subscription
    DataSources::ManagerService.unsubscribe(self)
  end

  # Hilfsmethode zum Speichern neuer Werte
  def store_value(value, stored_at: Time.current)
    data_source_storages.create!(value: value, stored_at: stored_at)
  end

  def mark_attempt!
    update!(last_attempt_at: Time.current)
  end

  def mark_success!
    update!(status: :ok, last_success_at: Time.current, last_error: nil)
  end

  def mark_error!(message)
    update!(status: :error, last_error: message)
  end

  def job_running?
    return false unless auto_subscribe?
    return false if last_attempt_at.blank?

    case source_type.to_sym
    when :json_api
      interval = typed_config.interval
      return false unless interval.is_a?(Numeric)

      last_attempt_at > (Time.current - (interval.to_f * 2).seconds)
    when :mqtt
      last_attempt_at > 2.minutes.ago
    else
      false
    end
  rescue StandardError
    false
  end

  # Hilfsmethode zum Abrufen der neuesten Werte
  def latest_values(limit: 10)
    data_source_storages.recent.limit(limit)
  end

  # Hilfsmethode zum Abrufen des letzten gespeicherten Werts
  def latest_value
    data_source_storages.recent.first
  end

  # Gibt zurück ob in letzter Zeit Daten empfangen wurden
  def receiving_data?(within: 5.minutes)
    data_source_storages.since(within.ago).exists?
  end

  # Statistik über gespeicherte Daten
  def storage_stats
    {
      total_count: data_source_storages.count,
      oldest: data_source_storages.oldest_first.first&.stored_at,
      newest: data_source_storages.recent.first&.stored_at,
      last_24h_count: data_source_storages.since(24.hours.ago).count
    }
  end

  private

  def auto_subscribe?
    # Standardmäßig automatisch subscriben, kann über Config überschrieben werden
    (config || {}).with_indifferent_access[:auto_subscribe] != false
  end
end
