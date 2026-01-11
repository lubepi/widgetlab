import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.open()

    this.beforeCacheHandler = () => this.forceCleanup()
    document.addEventListener("turbo:before-cache", this.beforeCacheHandler)
  }

  disconnect() {
    this.close()

    if (this.beforeCacheHandler) {
      document.removeEventListener("turbo:before-cache", this.beforeCacheHandler)
      this.beforeCacheHandler = null
    }
  }

  open() {
    document.body.classList.add("modal-open")
    document.body.style.overflow = "hidden"

    if (!document.getElementById("turbo-modal-backdrop")) {
      const backdrop = document.createElement("div")
      backdrop.className = "modal-backdrop fade show"
      backdrop.id = "turbo-modal-backdrop"
      document.body.appendChild(backdrop)
      this.backdrop = backdrop
    }
  }

  close() {
    const hasAnyOtherOpenModal = !!document.querySelector(".modal.show")
    if (hasAnyOtherOpenModal) return

    document.body.classList.remove("modal-open")
    document.body.style.overflow = ""

    const backdrop = document.getElementById("turbo-modal-backdrop")
    if (backdrop) backdrop.remove()
  }

  forceCleanup() {
    document.body.classList.remove("modal-open")
    document.body.style.overflow = ""

    const backdrop = document.getElementById("turbo-modal-backdrop")
    if (backdrop) backdrop.remove()
  }
}
