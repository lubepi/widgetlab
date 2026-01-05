import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel"]
  static values = {
    open: { type: Boolean, default: false }
  }

  connect() {
    this.closeOnEscape = this.closeOnEscape.bind(this)
  }

  open(event) {
    event?.preventDefault()
    this.openValue = true
    this.panelTarget.classList.add('show')
    document.body.style.overflow = 'hidden'
    document.addEventListener('keydown', this.closeOnEscape)
  }

  close(event) {
    event?.preventDefault()
    this.openValue = false
    this.panelTarget.classList.remove('show')
    document.body.style.overflow = ''
    document.removeEventListener('keydown', this.closeOnEscape)
  }

  closeOnEscape(event) {
    if (event.key === 'Escape') {
      this.close()
    }
  }

  clickOutside(event) {
    if (event.target === this.panelTarget) {
      this.close()
    }
  }

  disconnect() {
    document.removeEventListener('keydown', this.closeOnEscape)
    document.body.style.overflow = ''
  }
}
