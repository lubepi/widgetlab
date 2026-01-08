# Bootstrap Installation - Abgeschlossen ✓

Bootstrap 5.3 wurde erfolgreich in diesem Rails 8 Projekt installiert.

## Was wurde installiert:

### 1. Ruby Gems
- **bootstrap** (~> 5.3) - Bootstrap CSS Framework
- **dartsass-rails** - Sass-Prozessor für Rails 8

### 2. JavaScript (via Importmap)
- **bootstrap** (@5.3.8) - Bootstrap JavaScript Komponenten
- **@popperjs/core** (@2.11.8) - Erforderlich für Bootstrap Dropdowns, Tooltips, etc.

## Dateien die modifiziert wurden:

### Gemfile
```ruby
gem "dartsass-rails"
gem "bootstrap", "~> 5.3"
```

### app/assets/stylesheets/application.scss
```scss
@use "bootstrap";
```

### app/javascript/application.js
```javascript
import "bootstrap"
```

### config/importmap.rb
```ruby
pin "bootstrap" # @5.3.8
pin "@popperjs/core", to: "@popperjs--core.js" # @2.11.8
```

## Entwicklung starten:

Um das Projekt mit automatischem CSS-Rebuild zu starten:

```bash
bin/dev
```

Dies startet sowohl den Rails Server (Port 3000) als auch den Sass-Watcher.

Alternativ manuell:

```bash
# Terminal 1: CSS bauen und beobachten
rails dartsass:watch

# Terminal 2: Rails Server starten
rails server
```

## Bootstrap verwenden:

### HTML-Komponenten in Views:
```erb
<div class="container">
  <div class="alert alert-success" role="alert">
    Bootstrap funktioniert!
  </div>
  
  <button class="btn btn-primary">Primary Button</button>
</div>
```

### JavaScript-Komponenten (Tooltips, Modals, etc.):
Bootstrap JavaScript ist bereits importiert und funktioniert automatisch mit data-bs-* Attributen.

```erb
<!-- Modal Beispiel -->
<button type="button" class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#exampleModal">
  Modal öffnen
</button>

<div class="modal fade" id="exampleModal" tabindex="-1">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title">Modal Titel</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
      </div>
      <div class="modal-body">
        Modal Inhalt hier...
      </div>
    </div>
  </div>
</div>
```

## Anpassungen:

Um Bootstrap anzupassen, kannst du Variablen vor dem Import überschreiben:

```scss
// In app/assets/stylesheets/application.scss

// Bootstrap Variablen überschreiben
$primary: #custom-color;
$font-family-base: 'Custom Font', sans-serif;

@use "bootstrap" with (
  $primary: #custom-color
);
```

## Dokumentation:

- Bootstrap 5 Docs: https://getbootstrap.com/docs/5.3/
- Bootstrap Ruby Gem: https://github.com/twbs/bootstrap-rubygem
- Dart Sass Rails: https://github.com/rails/dartsass-rails

## Troubleshooting:

### "foreman: not found" Fehler

Falls du die Fehlermeldung `foreman: not found` erhältst, wurde dies bereits behoben:
- Foreman wurde zum Gemfile hinzugefügt
- `bin/dev` wurde aktualisiert um `bundle exec foreman` zu verwenden
- Führe `bundle install` aus falls noch nicht geschehen

Jetzt sollte `bin/dev` problemlos funktionieren!

## Bootstrap testen:

Eine Test-Seite mit verschiedenen Bootstrap-Komponenten wurde erstellt:

**Pfad:** `app/views/pages/bootstrap_demo.html.erb`
**Controller:** `app/controllers/pages_controller.rb`
**Route:** `/bootstrap_demo`

Nach dem Start des Servers mit `bin/dev` kannst du die Demo-Seite unter folgender URL aufrufen:

```
http://localhost:3000/bootstrap_demo
```

Diese Seite zeigt:
- Alerts (mit JavaScript Dismiss-Funktion)
- Buttons in allen Farben
- Cards
- Modal (testet Bootstrap JavaScript)
- Formulare
- Badges
- Spinner

Wenn alle Komponenten korrekt dargestellt werden und das Modal funktioniert, ist Bootstrap vollständig einsatzbereit!

