class CreateUserGroupRoles < ActiveRecord::Migration[8.1]
  def change
    create_table :user_group_roles do |t|
      t.references :user_group, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :role

      t.timestamps
    end
  end
end
