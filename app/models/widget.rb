class Widget < ApplicationRecord
  has_many :user_widget_roles, dependent: :destroy
  has_many :members, through: :user_widget_roles, source: :user

  has_many :dashboard_widgets, dependent: :destroy
  has_many :dashboards, through: :dashboard_widgets, source: :dashboard

  # Ein Widget hat genau eine Datenquelle (über den Transformer)
  has_one :widget_data_source_transformer, dependent: :destroy
  has_one :data_source, through: :widget_data_source_transformer

  enum :widget_type, { value: 0, line: 1, bar: 2, column: 3 }

  TIME_RANGE_UNITS = %w[minutes hours days weeks months].freeze
  GROUP_BY_OPTIONS = %w[minute hour day week month].freeze
  AGGREGATE_FUNCTIONS = %w[avg min max sum count].freeze

  validates :name, presence: true
  validates :widget_type, presence: true
  validates :time_range_unit, inclusion: { in: TIME_RANGE_UNITS }, allow_nil: true
  validates :group_by, inclusion: { in: GROUP_BY_OPTIONS }, allow_nil: true
  validates :aggregate_function, inclusion: { in: AGGREGATE_FUNCTIONS }, allow_nil: true

  # Widgets die dem User gehören (owner)
  scope :owned_by, ->(user) {
    joins(:user_widget_roles)
      .where(user_widget_roles: { user_id: user.id, role: :owner })
  }

  # Widgets die mit dem User geteilt wurden (viewer, aber nicht owner)
  scope :shared_with, ->(user) {
    joins(:user_widget_roles)
      .where(user_widget_roles: { user_id: user.id, role: :viewer })
  }

  # Alle Widgets auf die der User Zugriff hat
  scope :accessible_by, ->(user) {
    left_outer_joins(:user_widget_roles)
      .where("widgets.is_public = TRUE OR user_widget_roles.user_id = ?", user.id)
      .distinct
  }

  # Berechtigungen
  def owner?(user)
    return false if user.nil?
    user_widget_roles.exists?(user: user, role: :owner)
  end

  def viewer?(user)
    return false if user.nil?
    user_widget_roles.exists?(user: user, role: :viewer)
  end

  def can_view?(user)
    return true if is_public
    return false if user.nil?
    owner?(user) || viewer?(user)
  end

  def can_edit?(user)
    return false if user.nil?
    owner?(user)
  end

  def has_data_source_access?(user)
    return false if data_source.nil?
    return true if data_source.is_public
    return false if user.nil?
    
    group_ids = user.user_groups.pluck(:id)
    data_source.data_source_whitelists.exists?(
      whitelistable_type: 'User', whitelistable_id: user.id
    ) || data_source.data_source_whitelists.exists?(
      whitelistable_type: 'UserGroup', whitelistable_id: group_ids
    )
  end

  def add_owner(user)
    user_widget_roles.find_or_create_by!(user: user) do |role|
      role.role = :owner
    end
  end

  def add_viewer(user)
    user_widget_roles.find_or_create_by!(user: user) do |role|
      role.role = :viewer
    end
  end

  def owner
    user_widget_roles.find_by(role: :owner)&.user
  end

  # Berechnet die Start-Zeit basierend auf time_range_value und time_range_unit
  def time_range_start
    return 24.hours.ago if time_range_value.nil? || time_range_unit.nil?

    case time_range_unit
    when 'minutes'
      time_range_value.minutes.ago
    when 'hours'
      time_range_value.hours.ago
    when 'days'
      time_range_value.days.ago
    when 'weeks'
      time_range_value.weeks.ago
    when 'months'
      time_range_value.months.ago
    else
      24.hours.ago
    end
  end

  # Holt die Daten für dieses Widget basierend auf Konfiguration
  def fetch_data
    return nil unless data_source.present?

    if widget_type == 'value'
      latest_data
    else
      # Für Charts: Verwende aggregierte Daten mit Widget-Konfiguration
      aggregated_data(
        start_time: time_range_start,
        end_time: Time.current,
        group_by: (group_by || 'hour').to_sym,
        aggregate: (aggregate_function || 'avg').to_sym
      )
    end
  end

  # Holt die aktuellen Daten für das Widget von der verknüpften Datenquelle
  # Optional mit Transformation basierend auf der Transformer-Config
  def current_data(limit: 10)
    return nil unless data_source.present?

    transformer = widget_data_source_transformer
    raw_values = data_source.latest_values(limit: limit)

    raw_values.map do |storage|
      {
        value: transformer.transform(storage.value),
        stored_at: storage.stored_at.in_time_zone(Time.zone)
      }
    end
  end

  # Holt nur den letzten Wert
  def latest_data
    return nil unless data_source.present?

    storage = data_source.latest_value
    return nil unless storage

    {
      value: widget_data_source_transformer.transform(storage.value),
      stored_at: storage.stored_at.in_time_zone(Time.zone)
    }
  end

  # Holt Daten in einem Zeitbereich (älteste zuerst, für Graphen)
  def data_in_range(start_time:, end_time: Time.current)
    return [] unless data_source.present?

    transformer = widget_data_source_transformer
    storages = data_source.data_source_storages.in_time_range(start_time, end_time).oldest_first

    storages.map do |storage|
      {
        value: transformer.transform(storage.value),
        stored_at: storage.stored_at.in_time_zone(Time.zone)
      }
    end
  end

  # Holt aggregierte Daten für Graphen (gruppiert nach Stunde/Tag)
  # group_by: :hour, :day, :week
  # aggregate: :avg, :min, :max, :sum, :count
  def aggregated_data(start_time:, end_time: Time.current, group_by: :hour, aggregate: :avg)
    return [] unless data_source.present?

    transformer = widget_data_source_transformer

    storages = data_source.data_source_storages
                          .in_time_range(start_time, end_time)
                          .oldest_first

    # Gruppiere die Daten nach Zeitintervall
    grouped = storages.group_by do |storage|
      case group_by
      when :minute
        storage.stored_at.beginning_of_minute
      when :hour
        storage.stored_at.beginning_of_hour
      when :day
        storage.stored_at.beginning_of_day
      when :week
        storage.stored_at.beginning_of_week
      else
        storage.stored_at.beginning_of_hour
      end
    end

    # Aggregiere die Werte pro Gruppe
    grouped.map do |time, group_storages|
      values = group_storages.map { |s| transformer.transform(s.value) }
      numeric_values = values.select { |v| v.is_a?(Numeric) }

      aggregated_value = case aggregate
                         when :avg
                           numeric_values.any? ? (numeric_values.sum / numeric_values.size.to_f).round(2) : nil
                         when :min
                           numeric_values.min
                         when :max
                           numeric_values.max
                         when :sum
                           numeric_values.sum
                         when :count
                           numeric_values.size
                         else
                           numeric_values.any? ? (numeric_values.sum / numeric_values.size.to_f).round(2) : nil
                         end

      {
        value: aggregated_value,
        stored_at: time.in_time_zone(Time.zone),
        count: group_storages.size
      }
    end
  end
end
