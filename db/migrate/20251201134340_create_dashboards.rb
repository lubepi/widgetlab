class CreateDashboards < ActiveRecord::Migration[8.1]
  def change
    create_table :dashboards do |t|
      t.string :name
      t.integer :columns
      t.boolean :is_public
      t.string :icon

      t.timestamps
    end
  end
end
