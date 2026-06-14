# QuizTech 🧠

A clean, gradient-themed quiz application built with Flutter. Browse quizzes by
category, play timed multiple-choice rounds with instant audio feedback, resume
unfinished quizzes, and track your scores over time.

The **UI/UX and quiz functionality** are recreated from the original
`QuizTech-Technext-Intern` project, while the **architecture, folder structure,
and package choices** follow a feature-first MVVM pattern (Riverpod + GoRouter).

---

## ✨ Features

- **Category-based catalog** — Popular, Science, Mathematics, and Computer quizzes.
- **Live search** that auto-jumps to the matching category.
- **Timed quiz player** — 60 seconds per question with an auto-advance when time runs out.
- **Instant feedback** — correct/wrong highlighting plus `correct`, `wrong`, and `score` sound effects (toggleable).
- **Resume in progress** — partially played quizzes are saved and surface as "Continue Pending Quizzes" cards with a live countdown.
- **Auto-submit on expiry** — a background checker submits the score of any quiz whose time runs out.
- **Score tracking** — a total-score circle, per-quiz history, and a quiz-history feed on the home screen.
- **Animated profile pill** — the app-bar avatar slides to reveal your running total score.
- **Offline login** — sign in with any credentials (see [Login](#-login)).
- **Responsive layout** via `flutter_screenutil` (375 × 812 design baseline).

---

## 🛠 Tech Stack

| Concern            | Choice                                   |
| ------------------ | ---------------------------------------- |
| Framework          | Flutter (Dart SDK `^3.8.1`)              |
| State management   | `flutter_riverpod`                       |
| Navigation         | `go_router` (StatefulShellRoute)         |
| Local persistence  | `hive` / `hive_flutter`, `shared_preferences` |
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
├── bootstrap.dart                  # binding init, Hive open, runApp(ProviderScope)
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
│   │   └── presentation/{view, viewmodel}   # blank login
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
**Details** and **Play** screens are pushed on top of the shell. An auth
redirect sends signed-out users to the login screen and signed-in users to Home.

### State (Riverpod)

| Provider                       | Responsibility                                                        |
| ------------------------------ | --------------------------------------------------------------------- |
| `authViewModelProvider`        | Session state and offline login/logout                                |
| `quizCatalogViewModelProvider` | Category & search filtering, ongoing/played tracking, expiry checker  |
| `scoreViewModelProvider`       | Score history (latest-first)                                          |
| `soundViewModelProvider`       | Sound-effects on/off toggle                                           |

### Persistence

A single Hive box, `quiz_progress`, holds two maps:

- `all_quizzes` — in-progress quizzes (current question, selected answers, start time)
- `all_scores` — completed-attempt history per quiz

`shared_preferences` stores the login flag and email so a relaunch stays signed in.

---

## 🔐 Login

There is **no backend**. The login screen accepts **any non-empty email and
password** — a fake user profile is synthesized from the email and persisted
locally. Implementation:
`lib/features/auth/presentation/viewmodel/auth_viewmodel.dart`.

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (Dart `^3.8.1`)
- An Android emulator, iOS simulator, or a connected device

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
