import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["grid", "widget", "addPlaceholder"]
  static values = {
    dashboardId: Number,
    columns: { type: Number, default: 3 },
    editing: { type: Boolean, default: false }
  }

  connect() {
    this.cellSize = 150 // Base cell size in pixels
    this.gap = 24 // Gap between cells
    this.initializeGrid()
  }

  initializeGrid() {
    if (!this.hasGridTarget) return
    this.updateGridStyles()
  }

  updateGridStyles() {
    const grid = this.gridTarget
    grid.style.display = 'grid'
    grid.style.gridTemplateColumns = `repeat(${this.columnsValue}, 1fr)`
    grid.style.gap = `${this.gap}px`
    grid.style.gridAutoRows = 'minmax(150px, auto)'
  }

  toggleEditing(event) {
    event.preventDefault()
    this.editingValue = !this.editingValue
    this.element.classList.toggle('editing-mode', this.editingValue)
    
    // Update button text
    const btn = event.currentTarget
    const textSpan = btn.querySelector('.edit-btn-text')
    if (textSpan) {
      textSpan.textContent = this.editingValue ? 'Fertig' : 'Bearbeiten'
    }
    btn.classList.toggle('btn-primary', this.editingValue)
    btn.classList.toggle('btn-secondary', !this.editingValue)

    // Show/hide resize handles and drag indicators
    this.widgetTargets.forEach(widget => {
      widget.classList.toggle('widget-editable', this.editingValue)
    })

    // Show/hide add placeholder
    if (this.hasAddPlaceholderTarget) {
      this.addPlaceholderTarget.style.display = this.editingValue ? 'flex' : 'none'
    }
  }

  // Drag & Drop functionality
  dragStart(event) {
    if (!this.editingValue) {
      event.preventDefault()
      return
    }
    
    const widget = event.currentTarget.closest('[data-dashboard-grid-target="widget"]')
    if (!widget) return

    this.draggedWidget = widget
    widget.classList.add('dragging')
    
    event.dataTransfer.effectAllowed = 'move'
    event.dataTransfer.setData('text/plain', widget.dataset.widgetId)
    
    // Create ghost image
    const ghost = widget.cloneNode(true)
    ghost.style.opacity = '0.5'
    ghost.style.position = 'absolute'
    ghost.style.top = '-9999px'
    document.body.appendChild(ghost)
    event.dataTransfer.setDragImage(ghost, 50, 50)
    setTimeout(() => ghost.remove(), 0)
  }

  dragEnd(event) {
    if (this.draggedWidget) {
      this.draggedWidget.classList.remove('dragging')
      this.draggedWidget = null
    }
    
    // Remove all drop indicators
    this.element.querySelectorAll('.drop-indicator').forEach(el => el.remove())
  }

  dragOver(event) {
    if (!this.editingValue) return
    event.preventDefault()
    event.dataTransfer.dropEffect = 'move'
  }

  drop(event) {
    event.preventDefault()
    if (!this.editingValue || !this.draggedWidget) return

    const widgetId = event.dataTransfer.getData('text/plain')
    const targetWidget = event.target.closest('[data-dashboard-grid-target="widget"]')
    
    if (targetWidget && targetWidget !== this.draggedWidget) {
      // Swap positions
      const parent = this.gridTarget
      const widgets = Array.from(parent.querySelectorAll('[data-dashboard-grid-target="widget"]'))
      const draggedIndex = widgets.indexOf(this.draggedWidget)
      const targetIndex = widgets.indexOf(targetWidget)
      
      if (draggedIndex < targetIndex) {
        targetWidget.after(this.draggedWidget)
      } else {
        targetWidget.before(this.draggedWidget)
      }
      
      // Save new positions
      this.savePositions()
    }
  }

  // Resize functionality
  startResize(event) {
    if (!this.editingValue) return
    event.preventDefault()
    event.stopPropagation()
    
    const widget = event.currentTarget.closest('[data-dashboard-grid-target="widget"]')
    if (!widget) return
    
    this.resizingWidget = widget
    this.resizeDirection = event.currentTarget.dataset.direction
    this.startX = event.clientX
    this.startY = event.clientY
    this.startWidth = parseInt(widget.dataset.width) || 1
    this.startHeight = parseInt(widget.dataset.height) || 1
    
    widget.classList.add('resizing')
    
    document.addEventListener('mousemove', this.handleResize)
    document.addEventListener('mouseup', this.stopResize)
  }

  handleResize = (event) => {
    if (!this.resizingWidget) return
    
    const gridRect = this.gridTarget.getBoundingClientRect()
    const cellWidth = (gridRect.width - (this.columnsValue - 1) * this.gap) / this.columnsValue
    const cellHeight = 150 // Minimum cell height
    
    const deltaX = event.clientX - this.startX
    const deltaY = event.clientY - this.startY
    
    let newWidth = this.startWidth
    let newHeight = this.startHeight
    
    if (this.resizeDirection.includes('e')) {
      newWidth = Math.max(1, Math.min(this.columnsValue, Math.round(this.startWidth + deltaX / (cellWidth + this.gap))))
    }
    if (this.resizeDirection.includes('s')) {
      newHeight = Math.max(1, Math.round(this.startHeight + deltaY / (cellHeight + this.gap)))
    }
    
    this.resizingWidget.style.gridColumn = `span ${newWidth}`
    this.resizingWidget.style.gridRow = `span ${newHeight}`
    this.resizingWidget.dataset.width = newWidth
    this.resizingWidget.dataset.height = newHeight
  }

  stopResize = (event) => {
    if (this.resizingWidget) {
      this.resizingWidget.classList.remove('resizing')
      
      // Save the new size
      const widgetId = this.resizingWidget.dataset.widgetId
      const width = parseInt(this.resizingWidget.dataset.width) || 1
      const height = parseInt(this.resizingWidget.dataset.height) || 1
      
      this.saveWidgetSize(widgetId, width, height)
      
      this.resizingWidget = null
    }
    
    document.removeEventListener('mousemove', this.handleResize)
    document.removeEventListener('mouseup', this.stopResize)
  }

  savePositions() {
    const widgets = this.gridTarget.querySelectorAll('[data-dashboard-grid-target="widget"]')
    const positions = []
    
    widgets.forEach((widget, index) => {
      positions.push({
        id: widget.dataset.widgetId,
        position: index,
        width: parseInt(widget.dataset.width) || 1,
        height: parseInt(widget.dataset.height) || 1
      })
    })
    
    // Send to server
    fetch(`/dashboards/${this.dashboardIdValue}/update_widget_positions`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({ positions })
    }).catch(console.error)
  }

  saveWidgetSize(widgetId, width, height) {
    fetch(`/dashboards/${this.dashboardIdValue}/widgets/${widgetId}`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({ 
        dashboard_widget: { width, height }
      })
    }).catch(console.error)
  }

  removeWidget(event) {
    event.preventDefault()
    if (!confirm('Widget wirklich entfernen?')) return
    
    const widget = event.currentTarget.closest('[data-dashboard-grid-target="widget"]')
    const widgetId = widget.dataset.widgetId
    
    fetch(`/dashboards/${this.dashboardIdValue}/widgets/${widgetId}`, {
      method: 'DELETE',
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      }
    }).then(() => {
      widget.remove()
    }).catch(console.error)
  }
}
