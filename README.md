# NEXA — Application Mobile & Web

> Plateforme de révision pour les Classes Préparatoires Scientifiques Tunisiennes (MP, PC, TSI, Bio)

Application Flutter multiplateforme (Android, iOS, Web) connectée au backend NEXA.

---

## Stack technique

| Technologie | Rôle |
|---|---|
| **Flutter** | Framework UI multiplateforme |
| **Dart** | Langage |
| **Dio** | Client HTTP pour les appels API |
| **go_router** | Navigation entre écrans |
| **shared_preferences** | Stockage local du token JWT |

---

## Prérequis

- Flutter SDK (stable channel, 3.x+)
- Android Studio (pour l'émulateur Android)
- Xcode (Mac uniquement, pour iOS)
- Chrome (pour le mode web)
- Backend NEXA démarré sur `http://localhost:3000`

---

## Installation

```bash
# 1. Cloner le dépôt
git clone https://github.com/YOURNAME/nexa-frontend.git
cd nexa-frontend

# 2. Installer les dépendances
flutter pub get

# 3. Vérifier l'environnement
flutter doctor

# 4. Configurer l'URL du backend
# Ouvrir lib/core/api/api_client.dart
# Modifier baseUrl selon l'environnement :
#   Chrome/Web  : http://localhost:3000
#   Émulateur Android : http://10.0.2.2:3000
#   WSL→Windows : http://<IP_WSL>:3000

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
- **Authentification** — Connexion et inscription avec sélection école/filière
- **Accueil** — Dashboard avec XP, niveau, statistiques personnelles
- **Exercices** — Banque d'exercices filtrés par matière et difficulté
  - Système d'indices progressifs (jusqu'à 4 indices, -10% XP par indice)
  - QCM avec validation et correction instantanée
  - Affichage de la solution détaillée après soumission
  - Mise à jour XP en temps réel
- **Concours** — Annales officielles triées par année et filière
  - Parcours question par question
  - Indices progressifs avec pénalité XP
  - Correction instantanée + solution après chaque réponse
  - Résumé de session avec XP total
- **Classement** — Leaderboard avec podium top 3, filtres par filière
- **Forum** — Consultation et création de posts, réponses, likes

---

## Structure du projet

```
lib/
├── core/
│   ├── api/
│   │   └── api_client.dart       # Client HTTP Dio, gestion JWT
│   └── theme/
│       └── nexa_theme.dart       # Couleurs, thème global
├── features/
│   ├── auth/presentation/        # Login + inscription (un seul écran)
│   ├── home/presentation/        # Dashboard accueil
│   ├── exercises/presentation/   # Liste + résolution d'exercices
│   ├── contests/presentation/    # Bibliothèque concours + session
│   ├── leaderboard/presentation/ # Classement avec podium
│   └── forum/presentation/       # Forum communautaire
├── widgets/
│   └── shared_widgets.dart       # Composants réutilisables
└── main.dart                     # Point d'entrée, navigation, shell
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
| Red | `#EF4444` | Erreur, incorrect |

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
