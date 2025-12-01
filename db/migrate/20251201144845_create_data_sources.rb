class CreateDataSources < ActiveRecord::Migration[8.1]
  def change
    create_table :data_sources do |t|
      t.references :creator, null: false, foreign_key: { to_table: :users }
      t.string :name
      t.integer :source_type
      t.jsonb :config
      t.boolean :is_public

      t.timestamps
    end
  end
end
