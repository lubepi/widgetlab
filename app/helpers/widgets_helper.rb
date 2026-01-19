module WidgetsHelper
  # Bereitet die Daten für Chart.js auf (basierend auf Widget-Typ)
  def prepare_chart_data(widget, limit: 10)
    return {} unless widget.data_source.present?

    begin
      case widget.widget_type
      when 'pie'
        # Pie Charts: Letzte N Werte
        prepare_pie_chart_data(widget, limit)
      when 'line', 'bar', 'column'
        # Linien/Balken/Säulen: Aggregierte Daten über Zeit
        prepare_time_series_data(widget)
      else
        {}
      end
    rescue => e
      Rails.logger.error "Error preparing chart data for widget #{widget.id}: #{e.message}"
      { labels: [], values: [], label: widget.name }
    end
  end

  # Holt den aktuellsten Wert für Value-Widgets
  def widget_current_value(widget)
    return "Keine Daten" unless widget.data_source.present?
    
    begin
      latest = widget.latest_data
      return "Keine Daten" unless latest
      
      # Formatiere den Wert wenn es eine Zahl ist
      value = latest[:value]
      value.is_a?(Numeric) ? number_with_precision(value, precision: 2, strip_insignificant_zeros: true) : value
    rescue => e
      Rails.logger.error "Error getting current value for widget #{widget.id}: #{e.message}"
      "Fehler"
    end
  end

  # Formatiert den Widget-Typ für die Anzeige
  def widget_type_display(widget_type)
    {
      'value' => 'Wert',
      'line' => 'Liniendiagramm',
      'bar' => 'Balkendiagramm',
      'column' => 'Säulendiagramm',
      'pie' => 'Kreisdiagramm'
    }[widget_type] || widget_type.titleize
  end

  private

  # Bereitet Daten für Pie Charts auf
  def prepare_pie_chart_data(widget, limit)
    data_points = widget.current_data(limit: limit) || []
    
    {
      labels: data_points.map.with_index { |d, i| "Wert #{i + 1}" },
      values: data_points.map { |d| d[:value] },
      label: widget.name
    }
  end

  # Bereitet Zeitserien-Daten für Line/Bar/Column Charts auf
  def prepare_time_series_data(widget)
    data_source = widget.data_source
    return { labels: [], values: [], label: 'Keine Daten' } unless data_source

    # Verwende Widget-Konfiguration für Zeitbereich und Aggregation
    begin
      data_points = widget.aggregated_data(
        start_time: widget.time_range_start,
        end_time: Time.current,
        group_by: (widget.group_by || 'hour').to_sym,
        aggregate: (widget.aggregate_function || 'avg').to_sym
      ) || []
      
      # Begrenze die Anzahl der Datenpunkte basierend auf data_limit
      limit = widget.data_limit || 100
      data_points = data_points.last(limit) if data_points.size > limit
    rescue => e
      Rails.logger.error "Error with aggregated_data: #{e.message}"
      data_points = []
    end

    # Fallback auf data_in_range wenn aggregated_data nicht funktioniert oder leer ist
    if data_points.empty?
      begin
        data_points = widget.data_in_range(
          start_time: widget.time_range_start,
          end_time: Time.current
        ) || []
      rescue => e
        Rails.logger.error "Error with data_in_range: #{e.message}"
        data_points = []
      end
    end
    
    # Formatiere Zeit-Labels basierend auf group_by
    time_format = widget.time_label_format.presence || case widget.group_by
                                                       when 'minute' then "%H:%M"
                                                       when 'hour' then "%d.%m %H:%M"
                                                       when 'day' then "%d.%m"
                                                       when 'week' then "KW %U"
                                                       when 'month' then "%m.%Y"
                                                       else "%d.%m %H:%M"
                                                       end
    
    {
      labels: data_points.map { |d| d[:stored_at].strftime(time_format) },
      values: data_points.map { |d| d[:value] },
      label: widget.name
    }
  end

  # Gibt das passende Bootstrap Icon für einen Widget-Typ zurück
  def widget_icon_for(widget)
    case widget.widget_type
    when 'value'
      'hash'
    when 'line'
      'graph-up'
    when 'bar'
      'bar-chart-fill'
    when 'column'
      'bar-chart'
    when 'pie'
      'pie-chart-fill'
    else
      'grid'
    end
  end
end
