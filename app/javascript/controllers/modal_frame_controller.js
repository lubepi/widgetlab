import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.onFrameRender = () => this.cleanupAfterRender()
    this.onBeforeCache = () => this.forceCleanup()

    this.element.addEventListener("turbo:frame-render", this.onFrameRender)
    document.addEventListener("turbo:before-cache", this.onBeforeCache)
  }

  disconnect() {
    if (this.onFrameRender) {
      this.element.removeEventListener("turbo:frame-render", this.onFrameRender)
      this.onFrameRender = null
    }

    if (this.onBeforeCache) {
      document.removeEventListener("turbo:before-cache", this.onBeforeCache)
      this.onBeforeCache = null
    }
  }

  cleanupAfterRender() {
    const html = (this.element.innerHTML || "").trim()
    if (html === "") return this.forceCleanup()

    const hasAnyOpenModal = !!document.querySelector(".modal.show")
    if (!hasAnyOpenModal) this.forceCleanup()
  }

  forceCleanup() {
    document.body.classList.remove("modal-open")
    document.body.style.overflow = ""

    document.querySelectorAll(".modal-backdrop").forEach((el) => el.remove())
  }
}
