class AddTimeRangeToWidgets < ActiveRecord::Migration[8.1]
  def change
    add_column :widgets, :time_range_value, :integer, default: 24, comment: "Wert für den Zeitbereich (z.B. 24 für 24 Stunden)"
    add_column :widgets, :time_range_unit, :string, default: "hours", comment: "Einheit: minutes, hours, days, weeks, months"
    add_column :widgets, :data_limit, :integer, default: 100, comment: "Maximale Anzahl Datenpunkte"
    add_column :widgets, :group_by, :string, default: "hour", comment: "Gruppierung: minute, hour, day, week"
    add_column :widgets, :aggregate_function, :string, default: "avg", comment: "Aggregation: avg, min, max, sum, count"
  end
end
