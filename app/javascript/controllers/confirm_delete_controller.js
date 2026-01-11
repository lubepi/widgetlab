import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["title", "body", "confirmButton", "form"]

  connect() {
    this.modalEl = document.getElementById("confirmDeleteModal")
    if (this.modalEl && window.bootstrap && window.bootstrap.Modal) {
      this.modal = window.bootstrap.Modal.getOrCreateInstance(this.modalEl)
    }
  }

  open(event) {
    event.preventDefault()

    const button = event.currentTarget
    const url = button.dataset.deleteUrl
    const title = button.dataset.deleteTitle
    const message = button.dataset.deleteMessage

    if (!url) return

    if (this.hasTitleTarget && title) this.titleTarget.textContent = title
    if (this.hasBodyTarget && message) this.bodyTarget.textContent = message

    if (this.hasFormTarget) {
      this.formTarget.action = url
    }

    if (this.modal) {
      this.modal.show()
    } else if (this.modalEl) {
      this.modalEl.classList.add("show")
      this.modalEl.style.display = "block"
      document.body.classList.add("modal-open")

      if (!document.querySelector(".modal-backdrop")) {
        const backdrop = document.createElement("div")
        backdrop.className = "modal-backdrop fade show"
        document.body.appendChild(backdrop)
      }
    }
  }

  close() {
    if (this.modal) {
      this.modal.hide()
      return
    }

    if (!this.modalEl) return
    this.modalEl.classList.remove("show")
    this.modalEl.style.display = "none"

    document.body.classList.remove("modal-open")
    document.querySelectorAll(".modal-backdrop").forEach((el) => el.remove())
  }
}
