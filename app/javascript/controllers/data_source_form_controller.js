import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["typeSelect", "configContainer"]

  connect() {
    // Initialize form state on connect
    if (this.hasTypeSelectTarget) {
      if (!this.typeSelectTarget.disabled) {
        this.typeChanged()
      }
    }
  }

  async typeChanged() {
    if (this.typeSelectTarget.disabled) return

    const selectedType = this.typeSelectTarget.value
    
    if (!selectedType) {
      this.configContainerTarget.innerHTML = `
        <div class="alert alert-info">
          <i class="bi bi-info-circle"></i> Bitte wählen Sie einen Typ aus, um die Konfigurationsfelder anzuzeigen.
        </div>
      `
      return
    }

    // Show loading state
    this.configContainerTarget.innerHTML = `
      <div class="text-center py-4">
        <div class="spinner-border text-primary" role="status">
          <span class="visually-hidden">Lädt...</span>
        </div>
      </div>
    `

    try {
      // Fetch the config fields partial for the selected type
      const response = await fetch(`/data_sources/config_fields?type=${selectedType}`, {
        headers: {
          'Accept': 'text/html',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })

      if (response.ok) {
        const html = await response.text()
        this.configContainerTarget.innerHTML = html
      } else {
        throw new Error('Failed to load config fields')
      }
    } catch (error) {
      console.error('Error loading config fields:', error)
      this.configContainerTarget.innerHTML = `
        <div class="alert alert-danger">
          <i class="bi bi-exclamation-triangle"></i> Fehler beim Laden der Konfigurationsfelder.
        </div>
      `
    }
  }
}
