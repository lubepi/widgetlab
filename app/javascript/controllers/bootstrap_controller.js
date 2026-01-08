import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="bootstrap"
export default class extends Controller {
  connect() {
    console.log("Bootstrap controller connected")
  }

  openModal(event) {
    event.preventDefault()
    const modalId = event.currentTarget.dataset.bsTarget
    const modalElement = document.querySelector(modalId)

    if (modalElement && window.bootstrap) {
      const modal = new window.bootstrap.Modal(modalElement)
      modal.show()
    } else {
      console.error("Bootstrap oder Modal-Element nicht gefunden", modalElement, window.bootstrap)
    }
  }
}

