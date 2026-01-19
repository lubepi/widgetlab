class WidgetDataSourceTransformer < ApplicationRecord
  belongs_to :widget
  belongs_to :data_source

  # Transformiert einen Wert basierend auf der Transformer-Konfiguration
  # Config kann folgende Optionen enthalten:
  # - json_path: String - Extrahiert einen verschachtelten Wert (z.B. "data.temperature")
  # - multiply: Numeric - Multipliziert den Wert
  # - add: Numeric - Addiert zum Wert
  # - round: Integer - Rundet auf n Dezimalstellen
  # - format: String - "number", "string", "boolean"
  def transform(value)
    return value if config.blank?

    transformer_config = (config || {}).with_indifferent_access
    result = value

    # 1. JSON Path Extraktion
    if transformer_config[:json_path].present?
      result = extract_json_path(result, transformer_config[:json_path])
    end

    # 2. Numerische Transformationen (nur wenn das Ergebnis numerisch ist)
    if result.is_a?(Numeric)
      result = apply_numeric_transformations(result, transformer_config)
    end

    # 3. Format-Konvertierung
    if transformer_config[:format].present?
      result = apply_format(result, transformer_config[:format])
    end

    result
  end

  private

  def extract_json_path(data, path)
    return data unless data.is_a?(Hash)

    path.to_s.split(".").reduce(data) do |obj, key|
      case obj
      when Hash
        obj[key] || obj[key.to_sym]
      when Array
        # Unterstütze Array-Index-Zugriff wie "items.0.value"
        key.match?(/^\d+$/) ? obj[key.to_i] : obj
      else
        obj
      end
    end
  end

  def apply_numeric_transformations(value, config)
    result = value.to_f

    # Multiplikation
    if config[:multiply].present?
      result *= config[:multiply].to_f
    end

    # Addition
    if config[:add].present?
      result += config[:add].to_f
    end

    # Runden
    if config[:round].present?
      result = result.round(config[:round].to_i)
    end

    result
  end

  def apply_format(value, format)
    case format.to_s
    when "number"
      value.to_f
    when "integer"
      value.to_i
    when "string"
      # Handle floats that are actually integers (42.0 -> "42")
      if value.is_a?(Float) && value == value.to_i
        value.to_i.to_s
      else
        value.to_s
      end
    when "boolean"
      # Convert 0/0.0 to integer first to ensure consistent boolean conversion
      normalized_value = value.is_a?(Float) && value == value.to_i ? value.to_i : value
      ActiveModel::Type::Boolean.new.cast(normalized_value)
    else
      value
    end
  end
end
