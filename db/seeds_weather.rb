# Wetter-Beispieldatenquelle erstellen

user = User.first || User.create!(
  email: 'admin@example.com', 
  password: 'password', 
  password_confirmation: 'password'
)

puts "🌤️  Erstelle Wetter-Datenquelle..."

# Erstelle Wetter-Datenquelle für Frankfurt
weather_ds = DataSource.create!(
  name: 'Wetter Frankfurt',
  creator: user,
  source_type: :json_api,
  is_public: true,
  status: :ok,
  config: {
    url: 'https://api.open-meteo.com/v1/forecast',
    method: 'GET',
    headers: {},
    params: {
      latitude: 50.1109,
      longitude: 8.6821,
      current: 'temperature_2m,relative_humidity_2m,wind_speed_10m'
    },
    interval: 300,
    value_path: 'current.temperature_2m'
  }
)

# Erstelle realistische Beispieldaten für die letzten 24 Stunden
# Temperaturen folgen einer Sinuskurve (nachts kälter, nachmittags wärmer)
puts "📊 Erstelle 24 Stunden Beispieldaten..."

24.times do |i|
  hours_ago = 23 - i
  time = hours_ago.hours.ago
  
  # Berechne realistische Temperatur basierend auf Tageszeit
  hour_of_day = time.hour
  base_temp = 15.0
  daily_variation = Math.sin((hour_of_day - 6) * Math::PI / 12) * 5  # Max um 18 Uhr
  random_variation = rand(-1.0..1.0)
  
  temperature = (base_temp + daily_variation + random_variation).round(1)
  
  weather_ds.data_source_storages.create!(
    value: temperature,
    stored_at: time
  )
end

puts "✅ Wetter-Datenquelle erstellt!"
puts "   ID: #{weather_ds.id}"
puts "   Name: #{weather_ds.name}"
puts "   Datenpunkte: #{weather_ds.data_source_storages.count}"
puts ""
puts "📝 Du kannst jetzt Widgets mit dieser Datenquelle erstellen:"
puts "   - Value Widget: Zeigt aktuelle Temperatur"
puts "   - Line Widget: Zeigt Temperaturverlauf"
puts "   - Bar/Column Widget: Zeigt stündliche Temperaturen"
