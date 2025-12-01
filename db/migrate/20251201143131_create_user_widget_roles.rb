class CreateUserWidgetRoles < ActiveRecord::Migration[8.1]
  def change
    create_table :user_widget_roles do |t|
      t.references :widget, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :role

      t.timestamps
    end
  end
end
