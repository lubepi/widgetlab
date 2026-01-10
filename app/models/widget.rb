class Widget < ApplicationRecord
  has_many :user_widget_roles, dependent: :destroy
  has_many :members, through: :user_widget_roles, source: :user

  has_many :dashboard_widgets, dependent: :destroy
  has_many :dashboards, through: :dashboard_widgets, source: :dashboard

  # Ein Widget hat genau eine Datenquelle (über den Transformer)
  has_one :widget_data_source_transformer, dependent: :destroy
  has_one :data_source, through: :widget_data_source_transformer

  enum :widget_type, { value: 0, line: 1, bar: 2, column: 3, pie: 4 }

  validates :name, presence: true

  # Holt die aktuellen Daten für das Widget von der verknüpften Datenquelle
  # Optional mit Transformation basierend auf der Transformer-Config
  def current_data(limit: 10)
    return nil unless data_source.present?

    transformer = widget_data_source_transformer
    raw_values = data_source.latest_values(limit: limit)

    raw_values.map do |storage|
      {
        value: transformer.transform(storage.value),
        stored_at: storage.stored_at
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
      stored_at: storage.stored_at
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
        stored_at: storage.stored_at
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
        stored_at: time,
        count: group_storages.size
      }
    end
  end
end
