# QuizTech 🧠

A clean, gradient-themed quiz application built with Flutter. Sign up with
Firebase, browse quizzes by category, play timed multiple-choice rounds with
instant audio feedback, resume unfinished quizzes, and track your scores over
time.

The **UI/UX and quiz functionality** are recreated from the original
`QuizTech-Technext-Intern` project, while the **architecture, folder structure,
and package choices** follow a feature-first MVVM pattern (Riverpod + GoRouter),
with authentication backed by **Firebase**.

---

## ✨ Features

- **Firebase Authentication** — email/password **login** and **sign up**; the
  session is persisted by Firebase, so a relaunch keeps you signed in.
- **Category-based catalog** — Popular, Science, Mathematics, and Computer quizzes.
- **Live search** that auto-jumps to the matching category.
- **Timed quiz player** — 60 seconds per question with an auto-advance when time runs out.
- **Instant feedback** — correct/wrong highlighting plus `correct`, `wrong`, and `score` sound effects (toggleable).
- **Resume in progress** — partially played quizzes are saved and surface as "Continue Pending Quizzes" cards with a live countdown.
- **Auto-submit on expiry** — a background checker submits the score of any quiz whose time runs out.
- **Score tracking** — a total-score circle, per-quiz history, and a quiz-history feed on the home screen.
- **Animated profile pill** — the app-bar avatar slides to reveal your running total score.
- **Responsive layout** via `flutter_screenutil` (375 × 812 design baseline).

---

## 🛠 Tech Stack

| Concern            | Choice                                   |
| ------------------ | ---------------------------------------- |
| Framework          | Flutter (Dart SDK `^3.8.1`)              |
| Authentication     | `firebase_core`, `firebase_auth`         |
| State management   | `flutter_riverpod`                       |
| Navigation         | `go_router` (StatefulShellRoute)         |
| Local persistence  | `hive` / `hive_flutter`                  |
| Responsive sizing  | `flutter_screenutil`                     |
| Audio              | `audioplayers`                           |
| Forms & toasts     | `form_field_validator`, `fluttertoast`   |

---

## 🏗 Architecture

Feature-first **MVVM**. Each feature owns its screens (`view`), its Riverpod
state (`viewmodel`), and its local `widgets`. Cross-cutting code lives in `app/`
(wiring) and `core/` (services & utilities).

```
lib/
├── main.dart                       # entry point → bootstrap()
├── bootstrap.dart                  # binding init, Firebase init, Hive open, runApp(ProviderScope)
├── firebase_options.dart           # generated Firebase config (flutterfire configure)
├── app/
│   ├── app.dart                    # MaterialApp.router + ScreenUtilInit
│   ├── di/app_providers.dart       # shared singletons (storage service)
│   ├── router/
│   │   ├── app_router.dart         # GoRouter + auth redirect
│   │   └── app_routes.dart         # route path constants
│   ├── shell/
│   │   ├── main_shell_page.dart    # tab shell: gradient app bar + drawer
│   │   └── widgets/drawer_layout.dart
│   └── theme/
│       ├── app_colors.dart
│       └── app_theme.dart
├── core/
│   ├── services/quiz_storage_service.dart   # Hive `quiz_progress` wrapper
│   └── utils/score_utils.dart
├── features/
│   ├── auth/
│   │   └── presentation/
│   │       ├── view/{login_screen, signup_screen}
│   │       └── viewmodel/auth_viewmodel.dart   # Firebase login / sign up
│   ├── home/
│   │   └── presentation/{view, viewmodel, widgets}
│   ├── quiz/
│   │   ├── domain/models/quiz_model.dart
│   │   ├── data/quiz_dummy_data.dart
│   │   └── presentation/{view, viewmodel}   # details + play screens
│   ├── score/
│   │   └── presentation/{view, viewmodel}
│   └── profile/
│       └── presentation/view
└── global_widgets/
    └── avatar_with_score.dart
```

### Navigation

`GoRouter` drives everything. A `StatefulShellRoute.indexedStack` hosts three
branches — **Home**, **Score**, **Profile** — each keeping its own state. Tabs
are switched from the navigation **drawer** (matching the original UX). The quiz
**Details** and **Play** screens are pushed on top of the shell. An auth redirect
sends signed-out users to **Login** (allowing the **Sign Up** page) and signed-in
users to Home. The redirect reacts to Firebase's auth stream, so navigation
updates automatically on login/logout.

### State (Riverpod)

| Provider                       | Responsibility                                                        |
| ------------------------------ | --------------------------------------------------------------------- |
| `authViewModelProvider`        | Firebase auth session, login, sign up, and logout                     |
| `quizCatalogViewModelProvider` | Category & search filtering, ongoing/played tracking, expiry checker  |
| `scoreViewModelProvider`       | Score history (latest-first)                                          |
| `soundViewModelProvider`       | Sound-effects on/off toggle                                           |

### Persistence

A single Hive box, `quiz_progress`, holds two maps:

- `all_quizzes` — in-progress quizzes (current question, selected answers, start time)
- `all_scores` — completed-attempt history per quiz

The **auth session is persisted by Firebase** itself (via
`FirebaseAuth.authStateChanges()`), so a relaunch stays signed in without any
extra local storage.

---

## 🔐 Authentication

Auth is backed by **Firebase Authentication** (email/password):

- **Login** — `lib/features/auth/presentation/view/login_screen.dart`
- **Sign Up** — `lib/features/auth/presentation/view/signup_screen.dart`
  (captures a full name, saved to the Firebase profile as `displayName`)
- **ViewModel** — `lib/features/auth/presentation/viewmodel/auth_viewmodel.dart`
  drives state from `FirebaseAuth.authStateChanges()`.

You need your own Firebase project to run the app — see **Firebase setup** below.

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (Dart `^3.8.1`)
- An Android emulator, iOS simulator, or a connected device
- A Firebase project (free tier is fine)
- The [FlutterFire CLI](https://firebase.flutter.dev/docs/cli): `dart pub global activate flutterfire_cli`

### Firebase setup

1. Create a project in the [Firebase console](https://console.firebase.google.com).
2. Enable **Authentication → Sign-in method → Email/Password**.
3. From the project root, generate the config:

   ```bash
   flutterfire configure
   ```

   This creates `lib/firebase_options.dart` and the native config
   (`google-services.json` / `GoogleService-Info.plist`).

> The committed `firebase_options.dart` is currently configured for **Android**.
> Re-run `flutterfire configure` to add iOS / web for your own project.

### Install

```bash
flutter pub get
```

### Run

```bash
# Run on the default connected device
flutter run

# …or target a specific device (list them with `flutter devices`)
flutter run -d "Pixel 6"
```

On first launch you'll land on the login screen — tap **Sign Up** to create an
account (or add one in the Firebase console under Authentication → Users).

### Build a release APK

```bash
flutter build apk --release
```

---

## 📁 Assets

Quiz thumbnails, button icons, and the `correct` / `wrong` / `score` sound
effects live in `assets/`. Fonts (`Ubuntu`) live in `fonts/`. Both are declared
in `pubspec.yaml`.

---

## 🙏 Credits

- UI/UX & quiz logic adapted from **QuizTech-Technext-Intern**.
- Architecture & project structure inspired by the **Energiebee** app
  (feature-first MVVM with Riverpod + GoRouter).
