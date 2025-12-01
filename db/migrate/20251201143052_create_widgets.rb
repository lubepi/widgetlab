class CreateWidgets < ActiveRecord::Migration[8.1]
  def change
    create_table :widgets do |t|
      t.string :name
      t.string :description
      t.integer :type
      t.string :color
      t.boolean :is_public

      t.timestamps
    end
  end
end
