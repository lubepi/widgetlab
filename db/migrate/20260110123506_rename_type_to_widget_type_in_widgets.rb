class RenameTypeToWidgetTypeInWidgets < ActiveRecord::Migration[8.1]
  def change
    rename_column :widgets, :type, :widget_type
  end
end
