class CreateDashboardUserRoles < ActiveRecord::Migration[8.1]
  def change
    create_table :dashboard_user_roles do |t|
      t.references :dashboard, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :role

      t.timestamps
    end
  end
end
