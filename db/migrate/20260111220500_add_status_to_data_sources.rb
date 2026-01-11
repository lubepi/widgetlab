class AddStatusToDataSources < ActiveRecord::Migration[8.1]
  def change
    add_column :data_sources, :status, :integer, null: false, default: 0
    add_column :data_sources, :last_attempt_at, :datetime
    add_column :data_sources, :last_success_at, :datetime
    add_column :data_sources, :last_error, :text

    add_index :data_sources, :status
  end
end
