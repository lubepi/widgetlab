import { Controller } from "@hotwired/stimulus"

// Verbindet sich mit data-controller="widget-chart"
// Chart.js wird als globales Script geladen
export default class extends Controller {
  static values = {
    type: String,      // "line", "bar", "pie", etc.
    data: Object,      // Die Chart-Daten
    color: String      // Die Widget-Farbe
  }

  connect() {
    // Nur Chart erstellen, wenn ein gültiger Type vorhanden ist
    if (!this.hasTypeValue || !this.typeValue) {
      console.error('Widget Chart Controller: Kein widget_type vorhanden')
      return
    }
    this.createChart()
  }

  disconnect() {
    if (this.chart) {
      this.chart.destroy()
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
    const baseOptions = {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: {
          display: this.typeValue === 'pie'
        }
      }
    }

    // Spezielle Optionen für verschiedene Chart-Typen
    if (this.typeValue !== 'pie') {
      baseOptions.scales = {
        y: {
          beginAtZero: true
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
