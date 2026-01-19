import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["grid", "modeToggle", "addWidgetBtn"]
  static values = {
    columns: { type: Number, default: 12 },
    editMode: { type: Boolean, default: false },
    updateUrl: String
  }

  connect() {
    this.initGrid()
    this.updateModeUI()
    this.observeGridChanges()
  }

  disconnect() {
    if (this.grid) {
      this.grid.destroy(false)
    }
    if (this.observer) {
      this.observer.disconnect()
    }
    if (this.resizeHandler) {
      window.removeEventListener('resize', this.resizeHandler)
    }
  }

  initGrid() {
    if (!this.hasGridTarget) return

    // Berechne Cell Height basierend auf Viewport
    const cellHeight = this.calculateCellHeight()
    
    // Berechne Spaltenanzahl basierend auf Viewport
    const columns = this.getResponsiveColumns()
    
    const options = {
      column: columns,
      cellHeight: cellHeight,
      margin: 10,
      minRow: 1,
      maxRow: 50,
      float: true,
      disableOneColumnMode: true,
      staticGrid: !this.editModeValue,
      resizable: {
        handles: 'e, se, s, sw, w'
      },
      draggable: {
        handle: '.widget-drag-handle'
      }
    }

    this.grid = GridStack.init(options, this.gridTarget)
    
    // Resize Handler für responsive Cell Height und Columns
    this.resizeHandler = () => {
      const newCellHeight = this.calculateCellHeight()
      const newColumns = this.getResponsiveColumns()
      
      if (this.grid) {
        if (newCellHeight !== this.currentCellHeight) {
          this.currentCellHeight = newCellHeight
          this.grid.cellHeight(newCellHeight)
        }
        if (newColumns !== this.currentColumns) {
          this.currentColumns = newColumns
          this.grid.column(newColumns)
        }
      }
    }
    window.addEventListener('resize', this.resizeHandler)
    this.currentCellHeight = cellHeight
    this.currentColumns = columns

    // Event Listener für Änderungen
    this.grid.on('change', (event, items) => {
      if (this.editModeValue) {
        this.savePositions(items)
      }
    })

    // Event Listener für das Ende von Drag/Resize
    this.grid.on('dragstop resizestop', (event, el) => {
      // Position wird durch 'change' Event gespeichert
    })
  }

  toggleMode() {
    this.editModeValue = !this.editModeValue
    this.updateModeUI()
    
    if (this.grid) {
      this.grid.setStatic(!this.editModeValue)
    }
  }

  updateModeUI() {
    // Toggle Button Text/Icon aktualisieren
    if (this.hasModeToggleTarget) {
      const icon = this.modeToggleTarget.querySelector('i')
      const text = this.modeToggleTarget.querySelector('span')
      
      if (this.editModeValue) {
        if (icon) icon.className = 'bi bi-eye me-1'
        if (text) text.textContent = this.element.dataset.viewText || 'View'
        this.modeToggleTarget.classList.remove('btn-outline-primary')
        this.modeToggleTarget.classList.add('btn-primary')
      } else {
        if (icon) icon.className = 'bi bi-pencil me-1'
        if (text) text.textContent = this.element.dataset.editText || 'Edit'
        this.modeToggleTarget.classList.remove('btn-primary')
        this.modeToggleTarget.classList.add('btn-outline-primary')
      }
    }

    // Add Widget Button ein-/ausblenden
    if (this.hasAddWidgetBtnTarget) {
      this.addWidgetBtnTarget.style.display = this.editModeValue ? 'inline-flex' : 'none'
    }

    // Widget Controls ein-/ausblenden
    this.element.querySelectorAll('.widget-edit-controls').forEach(el => {
      el.style.display = this.editModeValue ? 'flex' : 'none'
    })

    // Drag Handles ein-/ausblenden
    this.element.querySelectorAll('.widget-drag-handle').forEach(el => {
      el.style.cursor = this.editModeValue ? 'move' : 'default'
      el.classList.toggle('drag-enabled', this.editModeValue)
    })

    // Grid Items visuell anpassen
    this.element.querySelectorAll('.grid-stack-item').forEach(el => {
      el.classList.toggle('edit-mode', this.editModeValue)
    })
  }

  async savePositions(items) {
    if (!this.updateUrlValue) return

    const positions = items.map(item => ({
      id: item.el.dataset.dashboardWidgetId,
      position_x: item.x,
      position_y: item.y,
      width: item.w,
      height: item.h
    }))

    try {
      const response = await fetch(this.updateUrlValue, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
          'Accept': 'application/json'
        },
        body: JSON.stringify({ positions: positions })
      })

      if (!response.ok) {
        console.error('Failed to save positions')
      }
    } catch (error) {
      console.error('Error saving positions:', error)
    }
  }

  async removeWidget(event) {
    const widgetEl = event.target.closest('.grid-stack-item')
    const dashboardWidgetId = widgetEl.dataset.dashboardWidgetId

    if (!confirm('Widget wirklich vom Dashboard entfernen?')) return

    try {
      const response = await fetch(`/dashboard_widgets/${dashboardWidgetId}`, {
        method: 'DELETE',
        headers: {
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
          'Accept': 'text/vnd.turbo-stream.html'
        }
      })

      if (response.ok) {
        this.grid.removeWidget(widgetEl)
      }
    } catch (error) {
      console.error('Error removing widget:', error)
    }
  }

  // Wird aufgerufen wenn ein neues Widget hinzugefügt wird (via Turbo Stream)
  addWidget(event) {
    const { id, x, y, w, h, content } = event.detail
    
    this.grid.addWidget({
      id: id,
      x: x || 0,
      y: y || 0,
      w: w || 2,
      h: h || 2,
      minW: 1,
      minH: 1,
      maxW: 4,
      maxH: 4,
      content: content
    })
  }

  // Findet die nächste freie Position im Grid
  findFreePosition(width = 2, height = 2) {
    const items = this.grid.getGridItems().map(el => {
      const node = el.gridstackNode
      return { x: node.x, y: node.y, w: node.w, h: node.h }
    })

    // Suche von oben links nach unten rechts
    for (let y = 0; y < 50; y++) {
      for (let x = 0; x <= this.columnsValue - width; x++) {
        const fits = !items.some(item => {
          return !(x + width <= item.x || x >= item.x + item.w ||
                   y + height <= item.y || y >= item.y + item.h)
        })
        if (fits) {
          return { x, y }
        }
      }
    }
    return { x: 0, y: 0 }
  }

  calculateCellHeight() {
    const width = window.innerWidth
    if (width < 768) {
      return 120 // Mobile: kleinere Zellen
    } else if (width < 992) {
      return 100 // Tablet: mittlere Zellen
    } else {
      return 100 // Desktop: Standard-Zellen
    }
  }

  getResponsiveColumns() {
    const width = window.innerWidth
    const configuredColumns = this.columnsValue
    
    if (width < 768) {
      return 1 // Mobile: immer 1 Spalte
    } else if (width < 992) {
      return Math.min(configuredColumns, 6) // Tablet: max 6 Spalten
    } else {
      return configuredColumns // Desktop: volle Spaltenanzahl
    }
  }

  // Beobachtet DOM-Änderungen um neue Widgets (via Turbo Stream) zu erkennen
  observeGridChanges() {
    if (!this.hasGridTarget) return

    this.observer = new MutationObserver((mutations) => {
      mutations.forEach((mutation) => {
        mutation.addedNodes.forEach((node) => {
          if (node.nodeType === Node.ELEMENT_NODE && node.classList.contains('grid-stack-item')) {
            // Neues Widget wurde hinzugefügt - dem Grid bekannt machen
            this.grid.makeWidget(node)
            
            // Edit Mode Status anwenden
            if (this.editModeValue) {
              node.classList.add('edit-mode')
              const controls = node.querySelector('.widget-edit-controls')
              if (controls) controls.style.display = 'flex'
              const handle = node.querySelector('.widget-drag-handle')
              if (handle) {
                handle.style.cursor = 'move'
                handle.classList.add('drag-enabled')
              }
            }
          }
        })
      })
    })

    this.observer.observe(this.gridTarget, { childList: true })
  }
}
