class DataSource < ApplicationRecord
  belongs_to :creator, class_name: "User", foreign_key: "creator_id"

  has_many :widget_data_source_transformers, dependent: :destroy
  has_many :widgets, through: :widget_data_source_transformers
end
