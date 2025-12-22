class DataSourceStorage < ApplicationRecord
  belongs_to :data_source

  validates :value, presence: true
  validates :stored_at, presence: true

  # Scopes für häufige Abfragen
  scope :recent, -> { order(stored_at: :desc) }
  scope :oldest_first, -> { order(stored_at: :asc) }
  scope :in_time_range, ->(start_time, end_time) { where(stored_at: start_time..end_time) }
  scope :since, ->(time) { where("stored_at >= ?", time) }
  scope :until, ->(time) { where("stored_at <= ?", time) }

  # Setze stored_at auf aktuelle Zeit, falls nicht gesetzt
  before_validation :set_stored_at, on: :create

  private

  def set_stored_at
    self.stored_at ||= Time.current
  end
end
