import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "toggleIcon"]
  static values = {
    defaultCollapsed: Boolean,
  }

  connect() {
    const stored = window.localStorage.getItem(this.storageKey())
    const collapsed = stored === null ? this.defaultCollapsedValue : stored === "true"
    this.apply(collapsed)
  }

  toggle() {
    const collapsed = !document.body.classList.contains("sidebar-collapsed")
    this.apply(collapsed)
    window.localStorage.setItem(this.storageKey(), String(collapsed))
  }

  apply(collapsed) {
    document.body.classList.toggle("sidebar-collapsed", collapsed)

    if (this.hasToggleIconTarget) {
      this.toggleIconTarget.classList.toggle("bi-chevron-bar-right", collapsed)
      this.toggleIconTarget.classList.toggle("bi-chevron-bar-left", !collapsed)
    }
  }

  storageKey() {
    return "widgetlab.sidebar.collapsed"
  }
}
