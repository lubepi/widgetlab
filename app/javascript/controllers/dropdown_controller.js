import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  connect() {
    this.closeOnClickOutside = this.closeOnClickOutside.bind(this)
  }

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()
    
    // Close all other dropdowns first
    document.querySelectorAll('.dropdown-menu.show').forEach(menu => {
      if (menu !== this.menuTarget) {
        menu.classList.remove('show')
      }
    })
    
    this.menuTarget.classList.toggle('show')
    
    if (this.menuTarget.classList.contains('show')) {
      document.addEventListener('click', this.closeOnClickOutside)
    } else {
      document.removeEventListener('click', this.closeOnClickOutside)
    }
  }

  closeOnClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.menuTarget.classList.remove('show')
      document.removeEventListener('click', this.closeOnClickOutside)
    }
  }

  disconnect() {
    document.removeEventListener('click', this.closeOnClickOutside)
  }
}
