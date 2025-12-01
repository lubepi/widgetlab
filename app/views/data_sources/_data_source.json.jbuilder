json.extract! data_source, :id, :creator_id, :name, :source_type, :config, :is_public, :created_at, :updated_at
json.url data_source_url(data_source, format: :json)
