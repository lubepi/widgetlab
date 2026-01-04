# WidgetLab

Ein Rails 8.1 Dashboard-Management-System für Widgets, Datenquellen und Benutzer.

## 📋 Voraussetzungen

### Mit Docker (Empfohlen) 🐳

Nur diese zwei Tools werden benötigt:
- **Docker**: >= 20.10
- **Docker Compose**: >= 2.0

### Ohne Docker (Lokal)

Falls du lieber lokal entwickeln möchtest:
- **Ruby**: 3.4.7 (siehe `.ruby-version`)
- **Rails**: ~> 8.1.1
- **PostgreSQL**: >= 13
- **Git**: Für Versionskontrolle

## 🚀 Schnellstart mit Docker (Empfohlen)

### 1. Repository klonen
```bash
git clone <repository-url>
cd widgetlab
```

### 2. Docker Container starten
```bash
docker-compose up
```

Das war's! Die Anwendung läuft jetzt auf `http://localhost:3000`

Beim ersten Start werden automatisch:
- Das Docker-Image gebaut
- PostgreSQL gestartet
- Dependencies installiert
- Datenbank erstellt und migriert

### 3. Container im Hintergrund starten
```bash
docker-compose up -d
```

### 4. Logs anzeigen
```bash
docker-compose logs -f web
```

### 5. Container stoppen
```bash
docker-compose down
```

## 🐳 Docker-Befehle

### Rails-Befehle im Container ausführen

```bash
# Rails Console
docker-compose exec web bin/rails console

# Migrations ausführen
docker-compose exec web bin/rails db:migrate

# Datenbank zurücksetzen
docker-compose exec web bin/rails db:reset

# Tests ausführen
docker-compose exec web bin/rails test

# Routes anzeigen
docker-compose exec web bin/rails routes

# Neue Migration erstellen
docker-compose exec web bin/rails generate migration MigrationName

# Rubocop
docker-compose exec web bin/rubocop

# Bash-Shell im Container
docker-compose exec web bash
```

### Container neu bauen
```bash
# Bei Änderungen am Gemfile oder Dockerfile
docker-compose build

# Oder komplett neu starten
docker-compose down
docker-compose up --build
```

### Datenbank-Container direkt zugreifen
```bash
docker-compose exec db psql -U widgetlab -d widgetlab_development
```

### Volumes löschen (kompletter Reset)
```bash
docker-compose down -v
docker-compose up
```

## 🖥️ Lokale Entwicklung (ohne Docker)

### Installation der Voraussetzungen

#### Ubuntu/Debian
```bash
# Ruby (über rbenv empfohlen)
sudo apt-get update
sudo apt-get install -y build-essential libssl-dev libreadline-dev zlib1g-dev libpq-dev

# PostgreSQL
sudo apt-get install -y postgresql postgresql-contrib

# Falls rbenv nicht installiert ist:
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
source ~/.bashrc
rbenv install 3.4.7
```

### Setup ohne Docker

```bash
# Dependencies installieren
bundle install

# Datenbank erstellen und migrieren
bin/rails db:prepare

# Server starten
bin/dev
```

Oder nutze das automatische Setup-Script:
```bash
bin/setup
```

## 🛠️ Nützliche Befehle

### Mit Docker
```bash
# Container Status
docker-compose ps

# Container neu starten
docker-compose restart web

# Einzelnen Service neu starten
docker-compose restart db

# Container Logs
docker-compose logs -f

# Container-Shell
docker-compose exec web bash

# Gem installieren
docker-compose exec web bundle install

# Assets precompile
docker-compose exec web bin/rails assets:precompile
```

### Lokal (ohne Docker)

#### Server starten
```bash
bin/dev          # Empfohlen
bin/rails server # Alternative
```

#### Konsole
```bash
bin/rails console
```

#### Datenbank
```bash
bin/rails db:migrate        # Migrationen ausführen
bin/rails db:rollback       # Letzte Migration zurück
bin/rails db:reset          # DB zurücksetzen
bin/rails db:seed           # Seed-Daten laden
```

#### Tests
```bash
bin/rails test              # Alle Tests
bin/rails test:system       # System-Tests
```

#### Code-Qualität
```bash
bin/rubocop                 # Linting
bin/brakeman                # Security-Check
bin/bundler-audit           # Gem-Sicherheit
bin/ci                      # Alle Checks
```

## 📦 Projekt-Struktur

```
app/
├── controllers/     # HTTP-Request-Handler
├── models/         # Datenmodelle (ActiveRecord)
├── views/          # Templates (ERB)
├── helpers/        # View-Helper
├── jobs/           # Background-Jobs
└── mailers/        # E-Mail-Templates

config/             # Konfiguration
├── routes.rb       # URL-Routing
├── database.yml    # Datenbank-Config
└── initializers/   # App-Initialisierung

db/
├── migrate/        # Datenbank-Migrationen
└── seeds.rb        # Seed-Daten

test/               # Tests
```

## 🔑 Wichtige Modelle

- **Dashboard**: Haupt-Dashboard-Verwaltung
- **Widget**: Widget-Komponenten
- **DashboardWidget**: Verknüpfung Dashboard ↔ Widget
- **DataSource**: Datenquellen für Widgets
- **User**: Benutzer-Management
- **UserGroup**: Benutzergruppen
- **Rollen-Modelle**: `*_role` für Berechtigungen

## 🔧 Nützliche Befehle

```bash
# Cache leeren
bin/rails tmp:clear

# Logs leeren
bin/rails log:clear

# Neue Controller generieren
bin/rails generate controller ControllerName action1 action2

# Neues Modell generieren
bin/rails generate model ModelName field:type

# Asset-Pipeline
bin/rails assets:precompile  # Production
bin/rails assets:clobber     # Cache löschen

# Jobs ausführen (Background)
bin/jobs
```


## 🌍 Environments

### Mit Docker
```bash
# Development (Standard)
docker-compose up

# Test-Environment
docker-compose exec web bash -c "RAILS_ENV=test bin/rails db:prepare"
docker-compose exec web bash -c "RAILS_ENV=test bin/rails test"

# Production Build (separates Dockerfile)
docker build -t widgetlab:prod .
docker run -p 80:80 -e RAILS_MASTER_KEY=<key> widgetlab:prod
```

### Lokal
```bash
# Development (Standard)
RAILS_ENV=development bin/rails s

# Test
RAILS_ENV=test bin/rails db:migrate

# Production
RAILS_ENV=production bin/rails assets:precompile
RAILS_ENV=production bin/rails s
```

## 🎯 Empfohlener Workflow

### Erster Start (Team-Setup)
1. Docker und Docker Compose installieren
2. Repository klonen: `git clone <url> && cd widgetlab`
3. Starten: `docker-compose up`
4. Im Browser öffnen: `http://localhost:3000`

### Tägliche Entwicklung
```bash
# Morgens starten
docker-compose up -d

# Arbeiten...

# Neue Migration nach git pull
docker-compose exec web bin/rails db:migrate

# Tests vor Commit
docker-compose exec web bin/rails test

# Abends stoppen
docker-compose down
```

### Neue Dependencies
```bash
# Nach Gemfile-Änderungen
docker-compose build
docker-compose up
```

## 🆘 Troubleshooting

### Docker-Probleme

#### Port bereits belegt
```bash
# Anderen Port verwenden - docker-compose.yml editieren:
# ports:
#   - "3001:3000"
```

#### Container läuft nicht
```bash
# Logs prüfen
docker-compose logs web

# Container neu bauen
docker-compose build --no-cache
docker-compose up
```

#### Datenbank-Verbindungsprobleme
```bash
# DB Container Status prüfen
docker-compose ps db

# DB Container neu starten
docker-compose restart db

# Warten bis DB bereit ist
docker-compose exec db pg_isready -U widgetlab
```

#### Gem-Änderungen werden nicht übernommen
```bash
# Container neu bauen
docker-compose down
docker-compose build
docker-compose up
```

#### Volumes löschen und neu starten
```bash
docker-compose down -v
docker-compose up
```

### Lokale Probleme (ohne Docker)

#### Port bereits belegt
```bash
# Prozess finden
lsof -i :3000
# Prozess beenden
kill -9 <PID>
```

#### Datenbank-Verbindungsfehler
```bash
# PostgreSQL-Status prüfen
sudo service postgresql status
# PostgreSQL starten
sudo service postgresql start
```

#### Gem-Probleme
```bash
bundle clean --force
bundle install
```

#### Kompletter Reset
```bash
bin/rails db:drop db:create db:migrate db:seed
```


## 📝 Wichtige Hinweise

### Datenbank-Konfiguration
Die PostgreSQL-Credentials sind in `docker-compose.yml` und `config/database.yml` definiert:
- **Username**: `widgetlab`
- **Password**: `12345678`
- **Host**: `db` (im Container) oder `localhost` (lokal)

### Credentials & Secrets
Rails 8 nutzt verschlüsselte Credentials:

```bash
# Mit Docker
docker-compose exec web bin/rails credentials:edit

# Lokal
bin/rails credentials:edit
```

### Daten-Persistenz
Docker Volumes sorgen dafür, dass Daten erhalten bleiben:
- `postgres_data`: Datenbank
- `bundle_cache`: Installierte Gems

Nur bei `docker-compose down -v` werden diese gelöscht!

## 📚 Weitere Ressourcen

- [Rails Guides](https://guides.rubyonrails.org/)
- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/)
- [PostgreSQL Docs](https://www.postgresql.org/docs/)
