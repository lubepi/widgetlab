json.extract! dashboard, :id, :name, :columns, :is_public, :icon, :created_at, :updated_at
json.url dashboard_url(dashboard, format: :json)
