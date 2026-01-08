class CreateDataSourceStorages < ActiveRecord::Migration[8.1]
  def change
    create_table :data_source_storages do |t|
      t.references :data_source, null: false, foreign_key: true
      t.jsonb :value, null: false, default: {}
      t.datetime :stored_at, null: false

      t.timestamps
    end

    add_index :data_source_storages, [:data_source_id, :stored_at]
    add_index :data_source_storages, :stored_at
  end
end
