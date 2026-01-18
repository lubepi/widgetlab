import { Controller } from "@hotwired/stimulus"

// Verbindet sich mit data-controller="widget-chart"
// Chart.js wird als globales Script geladen
export default class extends Controller {
  static values = {
    type: String,      // "line", "bar", "pie", etc.
    data: Object,      // Die Chart-Daten
    color: String,     // Die Widget-Farbe
    unit: String,      // Die Einheit (optional)
    name: String       // Der Widget-Name
  }

  connect() {
    // Nur Chart erstellen, wenn ein gültiger Type vorhanden ist
    if (!this.hasTypeValue || !this.typeValue) {
      console.error('Widget Chart Controller: Kein widget_type vorhanden')
      return
    }
    this.createChart()
    
    // Chart bei Theme-Änderung neu erstellen
    this.observer = new MutationObserver(() => {
      if (this.chart) {
        this.chart.destroy()
        this.createChart()
      }
    })
    this.observer.observe(document.documentElement, {
      attributes: true,
      attributeFilter: ['data-bs-theme']
    })
  }

  disconnect() {
    if (this.chart) {
      this.chart.destroy()
    }
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  createChart() {
    const ctx = this.element.getContext('2d')
    const chartData = this.prepareChartData()

    this.chart = new Chart(ctx, {
      type: this.typeValue === 'column' ? 'bar' : this.typeValue, // Column wird zu bar
      data: chartData,
      options: this.getChartOptions()
    })
  }

  prepareChartData() {
    const data = this.dataValue
    const color = this.colorValue || '#0d6efd'

    // Für Pie/Doughnut Charts
    if (this.typeValue === 'pie') {
      return {
        labels: data.labels || [],
        datasets: [{
          data: data.values || [],
          backgroundColor: this.generateColors(data.values?.length || 0, color),
          borderWidth: 1
        }]
      }
    }

    // Für Line/Bar/Column Charts
    return {
      labels: data.labels || [],
      datasets: [{
        label: data.label || 'Wert',
        data: data.values || [],
        backgroundColor: this.hexToRgba(color, 0.2),
        borderColor: color,
        borderWidth: 2,
        tension: 0.4 // Für glattere Linien
      }]
    }
  }

  getChartOptions() {
    const unit = this.hasUnitValue ? this.unitValue : ''
    const widgetName = this.hasNameValue ? this.nameValue : ''
    const isDark = document.documentElement.getAttribute('data-bs-theme') === 'dark'
    const textColor = isDark ? '#dee2e6' : '#212529'
    const gridColor = isDark ? 'rgba(255, 255, 255, 0.1)' : 'rgba(0, 0, 0, 0.1)'
    
    const baseOptions = {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        title: {
          display: this.typeValue !== 'pie' && widgetName,
          text: widgetName,
          color: textColor,
          font: {
            size: 14,
            weight: 'bold'
          },
          padding: {
            top: 5,
            bottom: 10
          }
        },
        legend: {
          display: this.typeValue === 'pie',
          labels: {
            color: textColor
          }
        },
        tooltip: {
          callbacks: {
            label: function(context) {
              let label = context.dataset.label || ''
              if (label) {
                label += ': '
              }
              if (context.parsed.y !== null) {
                label += context.parsed.y
              } else if (context.parsed !== null) {
                label += context.parsed
              }
              if (unit) {
                label += ' ' + unit
              }
              return label
            }
          }
        }
      }
    }

    // Spezielle Optionen für verschiedene Chart-Typen
    if (this.typeValue !== 'pie') {
      baseOptions.scales = {
        x: {
          display: true,
          title: {
            display: false
          },
          ticks: {
            maxTicksLimit: 8,
            color: textColor
          },
          grid: {
            color: gridColor
          }
        },
        y: {
          display: true,
          beginAtZero: false,
          title: {
            display: unit ? true : false,
            text: unit || '',
            color: textColor,
            font: {
              size: 11
            }
          },
          ticks: {
            color: textColor,
            callback: function(value) {
              // Runde auf maximal 2 Dezimalstellen, entferne trailing zeros
              if (typeof value === 'number') {
                return Number(value.toFixed(2))
              }
              return value
            }
          },
          grid: {
            color: gridColor
          }
        }
      }
    }

    return baseOptions
  }

  // Hilfsfunktion: Hex zu RGBA konvertieren
  hexToRgba(hex, alpha) {
    const r = parseInt(hex.slice(1, 3), 16)
    const g = parseInt(hex.slice(3, 5), 16)
    const b = parseInt(hex.slice(5, 7), 16)
    return `rgba(${r}, ${g}, ${b}, ${alpha})`
  }

  // Hilfsfunktion: Generiere mehrere Farben basierend auf einer Grundfarbe
  generateColors(count, baseColor) {
    const colors = []
    for (let i = 0; i < count; i++) {
      colors.push(this.hexToRgba(baseColor, 0.7 - (i * 0.1)))
    }
    return colors
  }
}
