class CreateUserGroups < ActiveRecord::Migration[8.1]
  def change
    create_table :user_groups do |t|
      t.string :name

      t.timestamps
    end
  end
end
