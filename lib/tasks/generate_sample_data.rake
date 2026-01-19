# frozen_string_literal: true

namespace :data do
  desc "Generate sample data for data sources (IDs 1, 3, 4, 5) for the last 30 days"
  task generate_samples: :environment do
    user = User.find(1)
    
    puts "Creating data sources for user #{user.id}..."
    create_data_sources(user)

    puts "\nDeleting existing data from DataSourceStorage..."
    deleted_count = DataSourceStorage.delete_all
    puts "  Deleted #{deleted_count} records."

    puts "\nGenerating sample data for data sources..."

    # Konfiguration
    days_back = 30
    end_time = Time.current

    # ID 1: Crypto Preise (Bitcoin, Ethereum, Tether)
    generate_crypto_data(1, days_back, end_time)

    # ID 3: Wetter Daten
    generate_weather_data(3, days_back, end_time)

    # ID 4: Währungskurse (EUR/USD)
    generate_currency_data(4, days_back, end_time)

    # ID 5: Raum C201 Thermo- & Hygrometer (MQTT)
    generate_room_sensor_data(5, days_back, end_time)

    puts "\nDone! Sample data generated for the last #{days_back} days."
  end

  def create_data_sources(user)
    # ID 1: CoinGecko Crypto API
    unless DataSource.exists?(id: 1)
      DataSource.create!(
        id: 1,
        name: "CoinGecko Simple Price API (Bitcoin, Ethereum, Tether in USD & EUR)",
        source_type: :json_api,
        creator: user,
        is_public: true,
        config: {
          url: "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum,tether&vs_currencies=usd,eur",
          method: "get",
          timeout: 30,
          interval: 300,
          auto_subscribe: false
        }
      )
      puts "  Created DataSource ID 1: CoinGecko API"
    else
      puts "  DataSource ID 1 already exists"
    end

    # ID 3: OpenMeteo Weather API
    unless DataSource.exists?(id: 3)
      DataSource.create!(
        id: 3,
        name: "OpenMeteo (Wiesbaden)",
        source_type: :json_api,
        creator: user,
        is_public: true,
        config: {
          url: "https://api.open-meteo.com/v1/forecast?latitude=50.0826&longitude=8.2416&current_weather=true",
          method: "get",
          timeout: 30,
          interval: 300,
          auto_subscribe: false
        }
      )
      puts "  Created DataSource ID 3: OpenMeteo API"
    else
      puts "  DataSource ID 3 already exists"
    end

    # ID 4: Frankfurter Currency API
    unless DataSource.exists?(id: 4)
      DataSource.create!(
        id: 4,
        name: "EZB Wechselkurse EUR/USD (Frankfurter API)",
        source_type: :json_api,
        creator: user,
        is_public: true,
        config: {
          url: "https://api.frankfurter.app/latest?from=EUR&to=USD",
          method: "get",
          timeout: 30,
          interval: 300,
          auto_subscribe: false
        }
      )
      puts "  Created DataSource ID 4: Frankfurter API"
    else
      puts "  DataSource ID 4 already exists"
    end

    # ID 5: MQTT Room Sensor
    unless DataSource.exists?(id: 5)
      DataSource.create!(
        id: 5,
        name: "Raum C201 (Thermo- & Hygrometer)",
        source_type: :mqtt,
        creator: user,
        is_public: false,
        config: {
          host: "localhost",
          port: 1883,
          topic: "sensors/c201",
          qos: 0,
          keep_alive: 15,
          parse_json: true,
          clean_session: false,
          use_ssl: false
        }
      )
      puts "  Created DataSource ID 5: MQTT Room Sensor"
    else
      puts "  DataSource ID 5 already exists"
    end
  end

  def generate_crypto_data(data_source_id, days_back, end_time)
    data_source = DataSource.find_by(id: data_source_id)
    unless data_source
      puts "DataSource #{data_source_id} not found, skipping..."
      return
    end

    interval = data_source.typed_config.interval rescue 60
    puts "\nGenerating crypto data for DataSource #{data_source_id} (interval: #{interval}s)..."

    base_values = {
      bitcoin_eur: 81981.0,
      bitcoin_usd: 95044.0,
      ethereum_eur: 2871.45,
      ethereum_usd: 3329.0,
      tether_eur: 0.862247,
      tether_usd: 0.99964
    }

    volatility = {
      bitcoin: 0.03,
      ethereum: 0.04,
      tether: 0.001
    }

    start_time = end_time - days_back.days
    current_time = start_time
    count = 0

    current = base_values.dup

    while current_time <= end_time
      current[:bitcoin_eur] *= (1 + rand(-volatility[:bitcoin]..volatility[:bitcoin]) * 0.1)
      current[:bitcoin_usd] *= (1 + rand(-volatility[:bitcoin]..volatility[:bitcoin]) * 0.1)
      current[:ethereum_eur] *= (1 + rand(-volatility[:ethereum]..volatility[:ethereum]) * 0.1)
      current[:ethereum_usd] *= (1 + rand(-volatility[:ethereum]..volatility[:ethereum]) * 0.1)
      current[:tether_eur] *= (1 + rand(-volatility[:tether]..volatility[:tether]) * 0.1)
      current[:tether_usd] *= (1 + rand(-volatility[:tether]..volatility[:tether]) * 0.1)

      value = {
        "bitcoin" => {
          "eur" => current[:bitcoin_eur].round(2),
          "usd" => current[:bitcoin_usd].round(2)
        },
        "ethereum" => {
          "eur" => current[:ethereum_eur].round(2),
          "usd" => current[:ethereum_usd].round(2)
        },
        "tether" => {
          "eur" => current[:tether_eur].round(6),
          "usd" => current[:tether_usd].round(5)
        }
      }

      DataSourceStorage.create!(
        data_source: data_source,
        value: value,
        stored_at: current_time
      )

      current_time += interval.seconds
      count += 1
      print "." if count % 1000 == 0
    end

    puts "\n  Created #{count} records for crypto data"
  end

  def generate_weather_data(data_source_id, days_back, end_time)
    data_source = DataSource.find_by(id: data_source_id)
    unless data_source
      puts "DataSource #{data_source_id} not found, skipping..."
      return
    end

    interval = data_source.typed_config.interval rescue 900
    puts "\nGenerating weather data for DataSource #{data_source_id} (interval: #{interval}s)..."

    start_time = end_time - days_back.days
    current_time = start_time
    count = 0

    base_temp = 2.0

    while current_time <= end_time
      hour = current_time.hour
      day_of_year = current_time.yday

      hour_effect = Math.sin((hour - 6) * Math::PI / 12) * 4
      random_effect = rand(-2.0..2.0)

      temperature = (base_temp + hour_effect + random_effect).round(1)

      windspeed = (rand(0.0..15.0) + rand(0.0..10.0)).round(1)
      winddirection = rand(0..359)

      weather_codes = [0, 0, 0, 1, 2, 3, 45, 51, 53, 61, 71, 73]
      weathercode = weather_codes.sample

      is_day = (hour >= 7 && hour < 18) ? 1 : 0

      value = {
        "latitude" => 50.08,
        "longitude" => 8.24,
        "timezone" => "GMT",
        "timezone_abbreviation" => "GMT",
        "elevation" => 123.0,
        "utc_offset_seconds" => 0,
        "generationtime_ms" => rand(1.5..3.5).round(4),
        "current_weather" => {
          "time" => current_time.strftime("%Y-%m-%dT%H:%M"),
          "interval" => 900,
          "temperature" => temperature,
          "windspeed" => windspeed,
          "winddirection" => winddirection,
          "is_day" => is_day,
          "weathercode" => weathercode
        },
        "current_weather_units" => {
          "time" => "iso8601",
          "interval" => "seconds",
          "temperature" => "°C",
          "windspeed" => "km/h",
          "winddirection" => "°",
          "is_day" => "",
          "weathercode" => "wmo code"
        }
      }

      DataSourceStorage.create!(
        data_source: data_source,
        value: value,
        stored_at: current_time
      )

      current_time += interval.seconds
      count += 1
      print "." if count % 500 == 0
    end

    puts "\n  Created #{count} records for weather data"
  end

  def generate_currency_data(data_source_id, days_back, end_time)
    data_source = DataSource.find_by(id: data_source_id)
    unless data_source
      puts "DataSource #{data_source_id} not found, skipping..."
      return
    end

    interval = data_source.typed_config.interval rescue 3600
    puts "\nGenerating currency data for DataSource #{data_source_id} (interval: #{interval}s)..."

    start_time = end_time - days_back.days
    current_time = start_time
    count = 0

    base_rate = 1.1617
    current_rate = base_rate

    while current_time <= end_time
      current_rate *= (1 + rand(-0.002..0.002))
      current_rate = current_rate.clamp(1.05, 1.25)

      value = {
        "base" => "EUR",
        "date" => current_time.strftime("%Y-%m-%d"),
        "amount" => 1.0,
        "rates" => {
          "USD" => current_rate.round(4)
        }
      }

      DataSourceStorage.create!(
        data_source: data_source,
        value: value,
        stored_at: current_time
      )

      current_time += interval.seconds
      count += 1
      print "." if count % 100 == 0
    end

    puts "\n  Created #{count} records for currency data"
  end

  def generate_room_sensor_data(data_source_id, days_back, end_time)
    data_source = DataSource.find_by(id: data_source_id)
    unless data_source
      puts "DataSource #{data_source_id} not found, skipping..."
      return
    end

    interval = 300

    puts "\nGenerating room sensor data for DataSource #{data_source_id} (interval: #{interval}s)..."

    start_time = end_time - days_back.days
    current_time = start_time
    count = 0

    base_temp = 21.0
    base_humidity = 45.0

    while current_time <= end_time
      hour = current_time.hour
      is_workday = current_time.wday.between?(1, 5)

      if is_workday && hour.between?(8, 18)
        temp_offset = rand(1.0..3.0)
        humidity_offset = rand(5.0..15.0)
      else
        temp_offset = rand(-2.0..0.5)
        humidity_offset = rand(-5.0..5.0)
      end

      temp = (base_temp + temp_offset + rand(-0.5..0.5)).round(1)
      humidity = (base_humidity + humidity_offset + rand(-2.0..2.0)).round(1)

      temp = temp.clamp(16.0, 28.0)
      humidity = humidity.clamp(25.0, 70.0)

      value = {
        "data" => {
          "temp" => temp,
          "humidity" => humidity
        },
        "topic" => "sensors/c201"
      }

      DataSourceStorage.create!(
        data_source: data_source,
        value: value,
        stored_at: current_time
      )

      current_time += interval.seconds
      count += 1
      print "." if count % 1000 == 0
    end

    puts "\n  Created #{count} records for room sensor data"
  end
end
