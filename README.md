# TRILL Covoit’

Application mobile de covoiturage quotidien et occasionnel, avec un partage transparent des frais, réalisée dans le cadre de la SAE du semestre 5 du BUT Informatique.

Ce dépôt contient l’application Flutter (`frontend/`) et l’API Spring Boot (`backend/`).

## Fonctionnalités prévues

- **Comptes et profils** : inscription, connexion et validation de l’adresse email.
- **Véhicules et trajets** : gestion des véhicules et publication d’offres de covoiturage.
- **Recherche et réservations** : recherche de trajets, demande de place et gestion des demandes par le conducteur.
- **Partage des frais** : estimation des participations et paiements simulés ou en environnement de test, sans argent réel.

Le projet est en cours de développement. Le dépôt contient actuellement les bases du frontend et du backend.

## Stack technique

- **Application mobile** : Dart / Flutter, pour Android et iOS.
- **API** : Java 21 / Spring Boot 4.1.1.
- **Base de données** : PostgreSQL.
- **Conteneurs** : Docker Compose.
- **Compilation et tests du backend** : Maven Wrapper.

## Démarrage

### Prérequis

- JDK 21.
- Flutter incluant Dart 3.11.4 ou une version 3.x ultérieure, conformément au `pubspec.yaml` du frontend.
- Un appareil ou un émulateur configuré pour Flutter. Le développement iOS nécessite macOS et Xcode.

### Cloner le dépôt

```powershell
git clone https://github.com/trill-covoit-team/trill-covoit.git
cd trill-covoit
```

Ouvrir `backend/` dans l’IDE Java et `frontend/` dans l’IDE Flutter. Les deux projets peuvent être ouverts simultanément ; ils partagent la même branche Git dans cette copie du dépôt.

### Lancer le backend

Depuis la racine du dépôt, ouvrir un terminal et accéder au backend :

```powershell
cd backend
```

Sous Windows :

```powershell
.\mvnw.cmd spring-boot:run
```

L’API démarre par défaut sur `http://localhost:8080`. Il est également possible de lancer la classe `CovoitApiApplication` avec le bouton Run / Debug de l’IDE.

Maven est fourni par le Wrapper : aucune installation séparée de Maven n’est nécessaire. Aucun endpoint métier n’est encore disponible.

### Lancer le frontend

Depuis la racine du dépôt, dans un second terminal :

```powershell
cd frontend
flutter pub get
flutter run
```

L’application affiche actuellement un écran de démarrage « Hello World! ».

## Équipe

- Thibault Lenoir.
- Raphaël Valiere.
- Ian Bin Syahrul Azlan.
- Leul Mulugeta.
- Lucas Récan.
