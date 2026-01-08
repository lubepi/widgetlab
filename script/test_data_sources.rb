#!/usr/bin/env ruby
# Beispiel-Script zum Testen der DataSource Services
# Führe aus mit: rails runner script/test_data_sources.rb

puts "=== DataSource Service Test ==="
puts

# Finde oder erstelle einen Test-User
user = User.first || User.create!(
  email: "test@example.com",
  first_name: "Test",
  last_name: "User"
)
puts "Using user: #{user.email}"
puts

# 1. JSON API Datenquelle mit Config-Klasse erstellen
puts "1. Creating JSON API Data Source with Config class..."
json_config = DataSources::Configs::JsonApi.build do |c|
  c.url("https://jsonplaceholder.typicode.com/posts/1")
  c.get
  c.timeout(30)
  c.interval(60)
end

json_source = DataSources::ManagerService.create_and_subscribe(
  creator: user,
  name: "JSONPlaceholder Test API (with Config)",
  source_type: :json_api,
  config: json_config,
  is_public: true,
  auto_subscribe: false
)
puts "✓ Created JSON API source: #{json_source.name} (ID: #{json_source.id})"
puts "  Config class: #{json_source.typed_config.class}"
puts

# 2. JSON API mit Hash erstellen (alte Methode - funktioniert weiterhin)
puts "2. Creating JSON API Data Source with Hash (legacy)..."
json_source_hash = DataSources::ManagerService.create_and_subscribe(
  creator: user,
  name: "JSONPlaceholder Test API (with Hash)",
  source_type: :json_api,
  config: {
    url: "https://jsonplaceholder.typicode.com/posts/2",
    method: "get",
    interval: 60
  },
  is_public: true,
  auto_subscribe: false
)
puts "✓ Created JSON API source: #{json_source_hash.name} (ID: #{json_source_hash.id})"
puts "  Typed config works: #{json_source_hash.typed_config.url}"
puts

# 3. Manuell Daten von der JSON API abrufen
puts "3. Fetching data from JSON API..."
subscriber = DataSources::JsonApiSubscriber.new(json_source)
result = subscriber.fetch_and_store
if result[:success]
  puts "✓ Successfully fetched and stored data"
  puts "  Value keys: #{result[:value].keys.join(', ')}"
else
  puts "✗ Failed to fetch data: #{result[:error]}"
end
puts

# 4. Typed Config verwenden
puts "4. Using typed config..."
typed_config = json_source.typed_config
puts "✓ Typed config attributes:"
puts "  URL: #{typed_config.url}"
puts "  Method: #{typed_config.method}"
puts "  Timeout: #{typed_config.timeout}s"
puts "  Interval: #{typed_config.interval}s"
puts

# 5. MQTT Datenquelle mit Config Builder erstellen
puts "5. Creating MQTT Data Source with Config builder..."
begin
  mqtt_config = DataSources::Configs::Mqtt.build do |c|
    c.host("test.mosquitto.org")
    c.port(1883)
    c.topic("test/widgetlab/sensor")
    c.qos(0)
    c.parse_json(true)
    c.clean_session(true)
  end

  mqtt_source = DataSources::ManagerService.create_and_subscribe(
    creator: user,
    name: "Test MQTT Sensor (with Config)",
    source_type: :mqtt,
    config: mqtt_config,
    is_public: false,
    auto_subscribe: false
  )
  puts "✓ Created MQTT source: #{mqtt_source.name} (ID: #{mqtt_source.id})"
  puts "  Config class: #{mqtt_source.typed_config.class}"

  typed_mqtt = mqtt_source.typed_config
  puts "  Host: #{typed_mqtt.host}"
  puts "  Port: #{typed_mqtt.port}"
  puts "  Topics: #{typed_mqtt.topics.join(', ')}"
  puts "  QoS: #{typed_mqtt.qos}"
rescue StandardError => e
  puts "✗ Failed to create MQTT source: #{e.message}"
end
puts

# 6. Config Validierung demonstrieren
puts "6. Demonstrating config validation..."
begin
  invalid_config = DataSources::Configs::JsonApi.new({ method: "get" })
  puts "✗ Should have thrown an error!"
rescue ArgumentError => e
  puts "✓ Validation works: #{e.message}"
end
puts

# 7. Builder Pattern Beispiele
puts "7. More builder pattern examples..."
weather_config = DataSources::Configs::JsonApi.build do |c|
  c.url("https://api.openweathermap.org/data/2.5/weather")
  c.get
  c.add_query_param("q", "Berlin")
  c.add_query_param("appid", "DEMO_KEY")
  c.add_header("Accept", "application/json")
  c.timeout(30)
  c.json_path("main.temp")
end
puts "✓ Created weather config with builder:"
puts "  URL: #{weather_config.url}"
puts "  Query params: #{weather_config.query_params.keys.join(', ')}"
puts "  Headers: #{weather_config.headers.keys.join(', ')}"
puts "  JSON path: #{weather_config.json_path}"
puts

# 8. Gespeicherte Werte anzeigen
puts "8. Retrieving stored values..."
latest = json_source.latest_value
if latest
  puts "✓ Latest value:"
  puts "  Stored at: #{latest.stored_at}"
  puts "  Value keys: #{latest.value.keys.join(', ')}"
else
  puts "✗ No values stored yet"
end
puts

# 9. Manuell einen Wert speichern
puts "9. Manually storing a value..."
manual_value = {
  temperature: 22.5,
  humidity: 60,
  timestamp: Time.current.to_i
}
stored = json_source.store_value(manual_value)
puts "✓ Manually stored value:"
puts "  Stored at: #{stored.stored_at}"
puts

# 10. Mehrere Werte abrufen
puts "10. Retrieving multiple values..."
values = json_source.latest_values(limit: 5)
puts "✓ Retrieved #{values.count} value(s):"
values.each_with_index do |v, i|
  puts "  #{i + 1}. #{v.stored_at} - #{v.value.keys.join(', ')}"
end
puts

puts "=== Test completed ==="
puts
puts "Summary:"
puts "- JSON API sources: #{DataSource.json_api.count}"
puts "- MQTT sources: #{DataSource.mqtt.count}"
puts "- Total stored values: #{DataSourceStorage.count}"
puts
puts "Config classes available:"
puts "- DataSources::Configs::JsonApi"
puts "- DataSources::Configs::Mqtt"
puts
puts "To clean up test data, run:"
puts "  DataSource.where('name LIKE ?', '%Test%').destroy_all"

