# Bootstrap Modal Fix

## Problem
Das Bootstrap Modal öffnete sich nicht, weil Bootstrap JavaScript nicht korrekt initialisiert wurde.

## Lösung

### 1. Bootstrap korrekt importieren (app/javascript/application.js)
```javascript
import * as bootstrap from "bootstrap"
window.bootstrap = bootstrap
```

Dies macht Bootstrap global verfügbar, sodass die JavaScript-Komponenten funktionieren.

### 2. Stimulus Controller erstellt (app/javascript/controllers/bootstrap_controller.js)
Ein Stimulus Controller wurde erstellt, der Bootstrap-Komponenten mit Turbo kompatibel macht:

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  openModal(event) {
    event.preventDefault()
    const modalId = event.currentTarget.dataset.bsTarget
    const modalElement = document.querySelector(modalId)
    
    if (modalElement && window.bootstrap) {
      const modal = new window.bootstrap.Modal(modalElement)
      modal.show()
    }
  }
}
```

### 3. Verwendung in Views

**Native Bootstrap (funktioniert jetzt):**
```erb
<button type="button" class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#exampleModal">
  Modal öffnen
</button>
```

**Mit Stimulus Controller (bessere Turbo-Kompatibilität):**
```erb
<div data-controller="bootstrap">
  <button type="button" class="btn btn-primary" 
          data-action="click->bootstrap#openModal" 
          data-bs-target="#exampleModal">
    Modal öffnen
  </button>
</div>
```

## Test

Nach dem Neustart des Servers (`bin/dev`) sollten beide Buttons auf der Bootstrap Demo-Seite funktionieren:
- http://localhost:3000/bootstrap_demo

Die Debug-Information auf der Seite zeigt den Status von Bootstrap JavaScript.

## Weitere Bootstrap-Komponenten mit Stimulus

Der gleiche Ansatz kann für andere Bootstrap-Komponenten verwendet werden:
- Tooltips
- Popovers
- Toasts
- Offcanvas
- etc.

Beispiel für Tooltips:
```javascript
// In bootstrap_controller.js
initTooltips() {
  const tooltipTriggerList = document.querySelectorAll('[data-bs-toggle="tooltip"]')
  const tooltipList = [...tooltipTriggerList].map(tooltipTriggerEl => 
    new window.bootstrap.Tooltip(tooltipTriggerEl)
  )
}
```

