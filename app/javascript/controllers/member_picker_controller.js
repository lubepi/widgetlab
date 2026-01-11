import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["query", "item", "checkbox", "count"]

  connect() {
    this.updateCount()
  }

  filter() {
    const q = (this.queryTarget.value || "").toLowerCase().trim()

    this.itemTargets.forEach((el) => {
      const haystack = (el.dataset.search || "").toLowerCase()
      el.classList.toggle("d-none", q.length > 0 && !haystack.includes(q))
    })
  }

  toggleAll(event) {
    const checked = event.params.checked === true
    this.checkboxTargets.forEach((cb) => {
      cb.checked = checked
    })
    this.updateCount()
  }

  updateCount() {
    if (!this.hasCountTarget) return
    const selected = this.checkboxTargets.filter((cb) => cb.checked).length
    const total = this.checkboxTargets.length
    this.countTarget.textContent = `${selected} / ${total} ausgewählt`
  }
}
