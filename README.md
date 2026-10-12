# TRILL Covoit’

Application mobile de covoiturage quotidien et occasionnel, avec un partage transparent des frais, réalisée dans le cadre de la SAE du semestre 5 du BUT Informatique.

Ce dépôt contient l’application Flutter (`frontend/`) et l’API Spring Boot (`backend/`).

## Fonctionnalités prévues

- **Comptes et profils** : inscription, connexion et validation de l’adresse email.
- **Véhicules et trajets** : gestion des véhicules et publication d’offres de covoiturage.
- **Recherche et réservations** : recherche de trajets, demande de place et gestion des demandes par le conducteur.
- **Partage des frais** : estimation des participations et paiements simulés ou en environnement de test, sans argent réel.

Le projet est en cours de développement.

## Stack technique

- **Application mobile** : Dart / Flutter, pour Android et iOS.
- **API** : Java 21 / Spring Boot 4.1.1.
- **Base de données** : PostgreSQL.
- **Migrations de la base** : Flyway.
- **Conteneurs** : Docker Compose.
- **Compilation et tests du backend** : Maven Wrapper.

## Démarrage

### Prérequis

- JDK 21.
- PostgreSQL, via Docker avec Docker Compose ou un serveur (installé ou hébergé).
- Flutter incluant Dart 3.11.4 ou une version 3.x ultérieure, conformément au `pubspec.yaml` du frontend.
- Un appareil ou un émulateur configuré pour Flutter. Le développement iOS nécessite macOS et Xcode.

### Lancer en local

1. Cloner le dépôt :

```powershell
git clone https://github.com/trill-covoit-team/trill-covoit.git
cd trill-covoit
```

Ouvrir `backend/` dans l’IDE Java et `frontend/` dans l’IDE Flutter. Les deux projets peuvent être ouverts simultanément ; ils partagent la même branche Git dans cette copie du dépôt.

2. Créer le fichier de configuration :

```powershell
cp .env.example .env
```

- **Avec Docker** : les valeurs par défaut conviennent (`DOCKER_ENABLED=true`). Docker doit être démarré et le port `DB_PORT` disponible.
- **Avec un autre serveur PostgreSQL** : définir `DOCKER_ENABLED=false` et adapter `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER` et `DB_PASSWORD`. Créer la base indiquée par `DB_NAME` avant le premier démarrage et vérifier que l’utilisateur configuré peut y accéder.

3. Lancer le backend (PowerShell) :

```powershell
cd backend
.\mvnw.cmd spring-boot:run
```

L’API démarre par défaut sur `http://localhost:8080`. Il est également possible de lancer la classe `CovoitApiApplication` avec le bouton Run / Debug de l’IDE.

Maven est fourni par le Wrapper : aucune installation séparée de Maven n’est nécessaire.

Avec `DOCKER_ENABLED=true`, Spring Boot démarre PostgreSQL automatiquement via Docker Compose.

4. Lancer le frontend depuis la racine du dépôt, dans un second terminal :

```powershell
cd frontend
flutter pub get
flutter run
```

### Tests

Depuis `backend/`, avec PostgreSQL disponible selon la configuration choisie :

```powershell
.\mvnw.cmd test
```

## Équipe

- Thibault Lenoir.
- Raphaël Valiere.
- Ian Bin Syahrul Azlan.
- Leul Mulugeta.
- Lucas Récan.
