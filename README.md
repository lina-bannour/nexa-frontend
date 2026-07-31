# NEXA — Application Mobile & Web

> Plateforme de révision pour les Classes Préparatoires Scientifiques Tunisiennes (MP, PT, PC, BG)

Application Flutter multiplateforme (Android, iOS, Web) connectée au backend NEXA — espace étudiant complet et back-office d'administration.

---

## Stack technique

| Technologie | Rôle |
|---|---|
| **Flutter** | Framework UI multiplateforme |
| **Dart** | Langage |
| **Dio** | Client HTTP pour les appels API |
| **go_router** | Navigation entre écrans |
| **flutter_riverpod** | Gestion d'état |
| **flutter_secure_storage** | Stockage sécurisé du token JWT |
| **flutter_math_fork** | Rendu LaTeX des énoncés/formules mathématiques |
| **image_picker** | Capture/sélection de photo (mode concours "résoudre sur papier") |
| **url_launcher** | Ouverture de liens externes (annales officielles) |

---

## Prérequis

- Flutter SDK (stable channel, 3.x+)
- Android Studio (pour l'émulateur Android)
- Xcode (Mac uniquement, pour iOS)
- Chrome (pour le mode web)
- Backend NEXA démarré sur `http://localhost:3000` ([nexa-backend](https://github.com/lina-bannour/nexa-backend))

---

## Installation

```bash
# 1. Cloner le dépôt
git clone https://github.com/lina-bannour/nexa-frontend.git
cd nexa-frontend

# 2. Installer les dépendances
flutter pub get

# 3. Vérifier l'environnement
flutter doctor

# 4. Configurer l'URL du backend
# Ouvrir lib/core/api/api_client.dart et modifier baseUrl selon l'environnement :
#   Chrome/Web         : http://localhost:3000
#   Émulateur Android   : http://10.0.2.2:3000
#   WSL → Windows       : http://<IP_WSL>:3000

# 5. Lancer l'application
flutter run -d chrome        # Web (Chrome)
flutter run -d android       # Émulateur Android
```

---

## Configuration de l'URL API

Le fichier `lib/core/api/api_client.dart` contient :

```dart
static const String baseUrl = 'http://172.20.24.88:3000';
```

Modifier cette valeur selon votre environnement de développement.

---

## Fonctionnalités implémentées

### Espace Étudiant
- **Authentification** — Connexion, inscription (école, filière MP/PT/PC/BG), vérification d'email, mot de passe oublié
- **Accueil** — XP, rang réel, streak, nombre d'exercices résolus, dernière activité
- **Exercices** — Banque filtrée par matière et difficulté
  - Vérification d'une réponse libre avant de révéler le QCM
  - Système d'indices progressifs (jusqu'à 4 indices, pénalité XP par indice — barème configurable côté admin)
  - QCM avec correction instantanée et solution détaillée
- **Concours** — Annales nationales, deux modes :
  - **QCM interactif** — parcours question par question, indices progressifs, correction instantanée, résumé de session
  - **Photo de copie** — résolution sur papier puis envoi d'une photo, avec renvoi vers le site officiel de l'annale (filière, année, matière)
- **Missions quotidiennes** — objectifs journaliers avec bonus XP
- **Classement** — Leaderboard avec podium top 3, filtres par filière et par période (semaine/mois/global), rang personnel
- **Forum** — Consultation, création de discussions, réponses, likes, signalement

### Back-office Administrateur
- **Dashboard** — KPIs globaux, répartition des étudiants par filière, activité récente
- **Analytique** — taux de réussite par matière/difficulté, exercices les plus difficiles, engagement concours, activité forum, rétention (streaks, statuts de comptes)
- **Étudiants** — recherche/filtres, fiche détail (XP, streak, exercices, dernière activité, progression XP sur 12 mois), suspension/réactivation, envoi de message
- **Contenu** — édition des exercices et concours (éditeur avec aperçu LaTeX en direct)
- **Modération** — file des discussions signalées, changement de statut des posts
- **Paramètres** — barème XP (pénalités par indice, bonus réponse directe), mode maintenance

---

## Structure du projet

```
lib/
├── core/
│   ├── api/
│   │   └── api_client.dart        # Client HTTP Dio, gestion JWT
│   └── theme/
│       └── nexa_theme.dart        # Couleurs, thème global
├── features/
│   ├── auth/presentation/         # Login, inscription, vérification email, mot de passe oublié
│   ├── home/presentation/         # Accueil, profil, progression
│   ├── exercises/presentation/    # Liste + résolution d'exercices
│   ├── contests/presentation/     # Bibliothèque concours, session QCM, soumission photo
│   ├── leaderboard/presentation/  # Classement avec podium
│   ├── forum/presentation/        # Forum communautaire
│   ├── maintenance/presentation/  # Écran de maintenance
│   └── admin/
│       ├── presentation/          # Dashboard, analytique, étudiants, contenu, modération, paramètres
│       └── widgets/               # Composants réutilisables du back-office (AdCard, AdBtn, AdModal…)
├── widgets/
│   └── shared_widgets.dart        # Composants réutilisables (espace étudiant)
└── main.dart                      # Point d'entrée, navigation, shell
```

---

## Palette de couleurs NEXA

| Nom | Hex | Usage |
|---|---|---|
| Navy | `#0B1D3A` | Fond principal, AppBar |
| Blue | `#126BFF` | Accent principal, boutons |
| Purple | `#6D3CFF` | Accent secondaire |
| Gold | `#FFC107` | XP, étoiles, podium |
| Green | `#10B981` | Succès, correct |
| Red | `#EF4444` | Erreur, incorrect, suspension |
| Orange | `#F97316` | Alertes |

---

## Build APK (Android)

```bash
flutter build apk --release
# APK généré dans : build/app/outputs/flutter-apk/app-release.apk
```

---

## Développé dans le cadre du projet NEXA
Plateforme de révision pour les classes préparatoires scientifiques tunisiennes.
Backend NestJS : [nexa-backend](https://github.com/lina-bannour/nexa-backend)
