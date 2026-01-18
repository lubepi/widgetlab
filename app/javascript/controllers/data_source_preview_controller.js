import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select", "preview", "content", "timestamp", "container"]

  connect() {
    // Initial load wenn Datenquelle bereits ausgewählt ist
    if (this.selectTarget.value) {
      this.loadPreview()
    }
  }

  loadPreview() {
    const dataSourceId = this.selectTarget.value

    if (!dataSourceId) {
      this.containerTarget.classList.add('d-none')
      return
    }

    const url = `/data_sources/${dataSourceId}/latest_response`

    fetch(url)
      .then(response => {
        if (!response.ok) {
          throw new Error('Keine Daten verfügbar')
        }
        return response.json()
      })
      .then(data => {
        // Formatiere JSON schön
        let formattedValue
        try {
          formattedValue = JSON.stringify(data.value, null, 2)
        } catch {
          formattedValue = String(data.value)
        }

        this.contentTarget.textContent = formattedValue
        this.timestampTarget.textContent = `Gespeichert am: ${data.stored_at}`
        this.containerTarget.classList.remove('d-none')
      })
      .catch(error => {
        this.contentTarget.textContent = `Keine Daten verfügbar: ${error.message}`
        this.timestampTarget.textContent = ''
        this.containerTarget.classList.remove('d-none')
      })
  }
}
