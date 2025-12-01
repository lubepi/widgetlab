class CreateDataSourceWhitelists < ActiveRecord::Migration[8.1]
  def change
    create_table :data_source_whitelists do |t|
      t.references :data_source, null: false, foreign_key: true
      t.references :whitelistable, polymorphic: true, null: false

      t.timestamps
    end
  end
end
