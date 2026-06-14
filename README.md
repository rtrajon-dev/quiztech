# QuizTech

A quiz app whose **UI/UX and functionality** are recreated from the original
`QuizTech-Technext-Intern` project, but whose **architecture, folder structure
and packages** follow the feature-first MVVM pattern used by the Energiebee app.

## Architecture

Feature-first MVVM with **Riverpod** (state) and **GoRouter** (navigation):

```
lib/
  main.dart                  # entry point → bootstrap()
  bootstrap.dart             # binding init, Hive box open, runApp(ProviderScope)
  app/
    app.dart                 # MaterialApp.router + ScreenUtilInit
    di/app_providers.dart    # shared singletons (storage service)
    router/                  # app_router.dart (GoRouter), app_routes.dart
    shell/                   # main_shell_page.dart + widgets/drawer_layout.dart
    theme/                   # app_colors.dart, app_theme.dart
  core/
    services/quiz_storage_service.dart   # Hive `quiz_progress` wrapper
    utils/score_utils.dart
  features/
    auth/   presentation/{view,viewmodel}        # blank login
    home/   presentation/{view,viewmodel,widgets} # catalog, search, history
    quiz/   domain/models, data, presentation/{view,viewmodel}  # details + play
    score/  presentation/{view,viewmodel}
    profile/presentation/view
  global_widgets/            # avatar_with_score.dart
```

Each feature owns its `presentation/view` (screens), `presentation/viewmodel`
(Riverpod `Notifier`s), and feature-local `widgets`. Models and seed data live
under the `quiz` feature's `domain/` and `data/` folders.

### Navigation
`GoRouter` with a `StatefulShellRoute.indexedStack` holding three branches —
Home, Score, Profile. Tabs are switched from the drawer (matching the original
UX); the quiz **Details** and **Play** screens are pushed over the shell.

### State
- `authViewModelProvider` — session (see login note below)
- `quizCatalogViewModelProvider` — categories, search, ongoing/played tracking,
  and the background timer that auto-submits expired quizzes
- `scoreViewModelProvider` — score history
- `soundViewModelProvider` — sound-effects toggle

### Persistence
Quiz progress (`all_quizzes`) and completed scores (`all_scores`) are stored in
a Hive box named `quiz_progress`, exactly as in the original app.

## Login (blank / offline)

There is **no backend**. The login screen accepts **any credentials** — a fake
user profile is synthesized from the email and the session is persisted with
`shared_preferences` so a relaunch stays signed in. See
`features/auth/presentation/viewmodel/auth_viewmodel.dart`.

## Run

```bash
flutter pub get
flutter run
```
