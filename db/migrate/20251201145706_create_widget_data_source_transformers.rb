class CreateWidgetDataSourceTransformers < ActiveRecord::Migration[8.1]
  def change
    create_table :widget_data_source_transformers do |t|
      t.references :widget, null: false, foreign_key: true
      t.references :data_source, null: false, foreign_key: true
      t.jsonb :config

      t.timestamps
    end
  end
end
