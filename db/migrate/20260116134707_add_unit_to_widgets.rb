class AddUnitToWidgets < ActiveRecord::Migration[8.1]
  def change
    add_column :widgets, :unit, :string
  end
end
