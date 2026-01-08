module DataSources
  module Configs
    # Basis-Konfigurationsklasse für alle Datenquellen
    class Base
      attr_reader :config_hash

      def initialize(config_hash)
        @config_hash = config_hash.with_indifferent_access
        validate!
      end

      # Konvertiert die Config zurück zu einem Hash für die Datenbank
      def to_h
        @config_hash
      end

      # Überprüft ob die Konfiguration gültig ist
      def valid?
        validate!
        true
      rescue ArgumentError
        false
      end

      # Gibt Validierungsfehler zurück
      def errors
        @errors ||= []
      end

      private

      def validate!
        @errors = []
        # Wird in Subklassen überschrieben
      end

      def add_error(message)
        @errors << message
      end

      def require_field(field, message = nil)
        unless @config_hash[field].present?
          message ||= "#{field} is required"
          add_error(message)
          raise ArgumentError, message
        end
      end

      def validate_type(field, *types)
        return unless @config_hash[field].present?

        value = @config_hash[field]
        unless types.any? { |type| value.is_a?(type) }
          message = "#{field} must be of type #{types.join(' or ')}"
          add_error(message)
          raise ArgumentError, message
        end
      end

      def validate_inclusion(field, allowed_values)
        return unless @config_hash[field].present?

        value = @config_hash[field]
        unless allowed_values.include?(value)
          message = "#{field} must be one of: #{allowed_values.join(', ')}"
          add_error(message)
          raise ArgumentError, message
        end
      end
    end
  end
end

