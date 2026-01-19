class AddTimeLabelFormatToWidgets < ActiveRecord::Migration[8.1]
  def change
    add_column :widgets, :time_label_format, :string, comment: "strftime Format für Zeit-Labels im Chart (z.B. %d.%m %H:%M)"
  end
end
