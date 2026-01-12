import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["icon", "label"]

  connect() {
    const theme = this.resolveInitialTheme()
    this.apply(theme)
  }

  toggle() {
    const current = this.currentTheme()
    const next = current === "dark" ? "light" : "dark"
    this.apply(next)
    window.localStorage.setItem(this.storageKey(), next)
  }

  resolveInitialTheme() {
    const stored = window.localStorage.getItem(this.storageKey())
    if (stored === "dark" || stored === "light") return stored

    const prefersDark = window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)").matches
    return prefersDark ? "dark" : "light"
  }

  currentTheme() {
    return document.documentElement.getAttribute("data-bs-theme") || "light"
  }

  apply(theme) {
    document.documentElement.setAttribute("data-bs-theme", theme)

    if (this.hasIconTarget) {
      this.iconTarget.classList.toggle("bi-moon-stars", theme === "dark")
      this.iconTarget.classList.toggle("bi-sun", theme !== "dark")
    }

    if (this.hasLabelTarget) {
      this.labelTarget.textContent = theme === "dark" ? "Dark Mode" : "Light Mode"
    }
  }

  storageKey() {
    return "widgetlab.theme"
  }
}
