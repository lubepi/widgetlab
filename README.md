# Widgetlab

Eine Rails-Anwendung für die Verwaltung von Dashboards und Widgets mit Echtzeit-Datenquellen.

## Systemvoraussetzungen

- **Ruby**: 3.4.7
- **Rails**: 8.1.1
- **PostgreSQL**: 18.1
- **Docker & Docker Compose**: Für Keycloak und MQTT
- **Node.js**: Für Asset-Kompilierung

## Erstmalige Einrichtung

### 1. Repository klonen und Dependencies installieren

```bash
git clone <repository-url>
cd widgetlab
bundle install
```

### 2. Umgebungsvariablen konfigurieren

Die Datei `.env` ist bereits vorhanden und enthält die Standardkonfiguration:

```env
POSTGRES_USER=widgetlab
POSTGRES_PASSWORD=12345678
POSTGRES_DB=widgetlab

POSTGRES_KEYCLOAK_DB=keycloak
POSTGRES_KEYCLOAK_USER=keycloak
POSTGRES_KEYCLOAK_PASSWORD=12345678

KEYCLOAK_ISSUER=http://localhost:8080/realms/widgetlab
KEYCLOAK_CLIENT_ID=widgetlab
KEYCLOAK_REDIRECT_URI=http://localhost:3000/auth/keycloak/callback
```

### 3. Docker-Services starten

Starte PostgreSQL, Keycloak und MQTT-Broker:

```bash
docker-compose up -d
```

Dies startet folgende Services:
- **PostgreSQL** (Port 5432) - Hauptdatenbank
- **PostgreSQL-Keycloak** (intern) - Keycloak-Datenbank
- **Keycloak** (Port 8080) - Authentifizierung
- **MQTT-Broker** (Ports 1883, 9001) - Messaging

### 4. Datenbank einrichten

```bash
bin/rails db:setup
# oder wenn die Datenbank bereits existiert:
bin/rails db:migrate
```

## Anwendung starten

### Entwicklungsmodus (empfohlen)

Startet Rails-Server und CSS-Compiler gleichzeitig:

```bash
bin/dev
```

Die Anwendung ist dann erreichbar unter:
- **Web-App**: http://localhost:3000
- **Keycloak**: http://localhost:8080
- **MQTT**: localhost:1883

### Alternative: Nur Rails-Server

```bash
bin/rails server
```

## Services verwalten

### Docker-Container Status prüfen

```bash
docker-compose ps
```

### Docker-Container stoppen

```bash
docker-compose down
```

### Logs anzeigen

```bash
# Alle Docker-Logs
docker-compose logs -f

# Nur spezifischer Service
docker-compose logs -f keycloak
```

## Datenbank-Management

```bash
# Neue Migration erstellen
bin/rails generate migration MigrationName

# Migrationen ausführen
bin/rails db:migrate

# Datenbank zurücksetzen
bin/rails db:reset

# Seed-Daten laden
bin/rails db:seed
```

## Tests ausführen

```bash
bin/rails test
bin/rails test:system
```

## Architektur

- **Backend**: Ruby on Rails 8.1.1
- **Frontend**: Hotwire (Turbo + Stimulus)
- **Styling**: Bootstrap 5.3.5 + Dart Sass
- **Datenbank**: PostgreSQL 18.1
- **Authentifizierung**: Keycloak (OpenID Connect)
- **Echtzeit**: MQTT (Eclipse Mosquitto)

## Troubleshooting

### Port bereits belegt

Wenn Port 3000, 5432 oder 8080 bereits belegt ist:

```bash
# Port-Nutzung prüfen
lsof -i :3000
lsof -i :5432
lsof :8080

# Prozess beenden
kill -9 <PID>
```

### Datenbankverbindung fehlgeschlagen

Prüfe, ob PostgreSQL-Container läuft:

```bash
docker-compose ps postgres
docker-compose logs postgres
```

### Keycloak-Fehler

Prüfe Keycloak-Logs:

```bash
docker-compose logs keycloak
```

## Entwicklung

### Code-Qualität

```bash
# RuboCop (Linter)
bin/rubocop

# Brakeman (Security Scanner)
bin/brakeman

# Bundler Audit (Dependency Check)
bin/bundler-audit
```
