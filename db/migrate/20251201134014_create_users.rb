class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :sub

      t.timestamps
    end
    add_index :users, :email, unique: true
    add_index :users, :sub, unique: true
  end
end
