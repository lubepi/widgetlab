class CreateDashboardWidgets < ActiveRecord::Migration[8.1]
  def change
    create_table :dashboard_widgets do |t|
      t.references :dashboard, null: false, foreign_key: true
      t.references :widget, null: false, foreign_key: true
      t.integer :width
      t.integer :height
      t.integer :position_x
      t.integer :position_y
      t.string :color

      t.timestamps
    end
  end
end
