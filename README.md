<div align="center">

# Pilates App

**Application de gestion de cours de Pilates**

Flutter · Firebase · Stripe

Gestion complète d'un studio : cours, programmes, réservations, paiements, avis et
messagerie — le tout en temps réel.

</div>

---

## À propos

Pilates App est une application mobile de gestion de studio de Pilates. Elle couvre le
parcours complet d'un cours : découvrir le programme, réserver une séance, s'acquitter en
ligne, suivre son planning et rester informé des annulations et nouveautés.

Coté serveur, l'application s'appuie entièrement sur **Firebase** comme backend : Firestore
pour les données, Authentication pour les comptes, Storage pour les médias et Cloud Functions
pour la logique. Aucune API intermédiaire n'est nécessaire.

## Fonctionnalités

### Pour le client

- **Inscription et connexion** par email / mot de passe via Firebase Auth
- **Catalogue des cours** avec description, durée et niveau
- **Réservation** d'une place, avec gestion des places disponibles
- **Calendrier** des séances via `table_calendar`
- **Paiement en ligne** par carte bancaire via **Stripe**
- **Messagerie** avec le studio (chat en temps réel)
- **Avis et notes** sur les cours suivis
- **Notifications locales** pour les rappels de séance
- **Vidéos de cours** intégrées depuis YouTube (`youtube_player_iframe`)
- **Galerie photo** avec sélection depuis l'appareil (`image_picker`)

### Pour l'administration

- **Tableau de bord admin** : gestion des cours, programmes et utilisateurs
- **File d'attente** lorsque les cours sont complets
- **Gestion des programmes** d'exercices

## Stack technique

| Couche | Technologies |
| --- | --- |
| Framework | **Flutter** (Dart, SDK ≥ 3.0) |
| Backend | **Firebase** — Auth, Firestore, Storage, Cloud Functions |
| Paiement | **Stripe** (`flutter_stripe`) |
| Calendrier | `table_calendar` |
| Vidéo | `youtube_player_iframe`, `webview_flutter` |
| UI | `google_fonts`, `cupertino_icons`, `cached_network_image` |
| Notifications | `flutter_local_notifications` |
| Formatage | `intl` |

## Plateformes supportées

Android · iOS · Web · Windows · macOS · Linux

## Installation

### Prérequis

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.0 ou plus
- Un projet **Firebase** et le fichier `google-services.json` / `GoogleService-Info.plist`

### Étapes

```bash
git clone https://github.com/anouar-coder/pilates_app.git
cd pilates_app
flutter pub get
```

Puis remplacez `lib/firebase_options.dart` par les options de **votre** projet Firebase.

### Lancer l'application

```bash
flutter run
```

### Tests

```bash
flutter test
```

## Configuration

| Élément | Où le configurer |
| --- | --- |
| Connexion Firebase | `lib/firebase_options.dart` |
| Clé publique Stripe | `lib/config/` |
| Identifiants `.env` | `lib/config/` |

## Structure du projet

```
lib/
  config/         configuration (Firebase, Stripe, clés)
  models/         cours, seance, programme, exercice, reservation,
                  paiement, avis, message, conversation, profil, admin
  screens/        accueil, auth, cours, programmes, reservations,
                  calendrier, paiement, avis, chat, notifications, admin
  services/       accès Firestore et logique métier (cours, réservation,
                  paiement, chat, notifications, programme, avis, profil)
  widgets/        composants d'interface réutilisables
  utils/          utilitaires
  main.dart       point d'entrée
```

L'architecture sépare strictement les **modèles** (données), les **services** (accès Firestore
et logique métier) et les **widgets** (présentation), ce qui facilite les tests et le
remplacement du backend.

## Fonctionnement par écran

| Écran | Rôle |
| --- | --- |
| `accueil` | Page d'accueil, aperçu des cours, raccourcis |
| `auth` | Connexion et inscription |
| `cours` | Liste et détail des cours |
| `programmes` | Programmes d'exercices par cours |
| `reservations` | Réservation et annulation |
| `calendrier` | Planning des séances |
| `paiement` | Tunnel de paiement Stripe |
| `avis` | Notation et commentaires |
| `chat` | Messagerie avec le studio |
| `notifications` | Centre de notifications |
| `admin` | Administration du studio |

## Contributeur

**Anwar Ben Brahim**

[![GitHub](https://img.shields.io/badge/GitHub-anouar--coder-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/anouar-coder)

> Le `README.md` d'origine (modèle Flutter par défaut) est conservé dans
> [`README.original.md`](./README.original.md).
