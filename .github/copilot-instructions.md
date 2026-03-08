# Copilot Instructions for Kangal_Android

## Project scope and entrypoint
- Primary app lives in `kangal/` (Flutter Android app). Work there unless a task explicitly targets root docs/assets.
- App bootstrap is `kangal/lib/main.dart`: constructs `AppDatabase`, creates Drift-backed repositories, then injects them via `MultiProvider`.
- UI root is `kangal/lib/app.dart` (`KangalApp` + `MaterialApp.router`).

## Architecture you should follow
- Current implemented stack: Flutter + `provider` DI/state, `go_router` navigation, Drift local DB, Freezed models.
- Data flow is layered: `UI -> Repository interface -> Drift repository impl -> DAO -> Drift tables`.
- Keep repository interfaces in `kangal/lib/data/repositories/*_repository.dart` and concrete Drift implementations in `drift_*_repository.dart`.
- Reuse existing DI pattern in `main.dart` (inject interfaces, not concrete types, where possible).

## Routing and app shell conventions
- Routing is centralized in `kangal/lib/routing/app_router.dart`.
- `AppRouter.createRouter()` is async and depends on `SharedPreferences` (`onboarding_complete`) for initial location.
- Main navigation uses `StatefulShellRoute.indexedStack` with 3 tabs: Dashboard (`/`), Transactions (`/transactions`), Settings (`/settings`).
- Add new routes in `AppRouter`; do not hardcode navigation structure in feature screens.

## Database and model conventions
- Drift DB setup is in `kangal/lib/data/database/app_database.dart`.
- `beforeOpen` seeds default categories via `DriftCategoryRepository.seedDefaultCategories()`.
- Transaction `date` is persisted as ISO string in Drift table and parsed back to `DateTime` in DAO mapping (`transactions_dao.dart`).
- Treat generated files as outputs: `*.g.dart`, `*.freezed.dart`, DAO mixins, and `app_database.g.dart`.

## Feature maturity expectations
- This repo includes PRD/plan docs at root (`PRD.md`, `plan/Plan.md`) that describe target milestones.
- Implemented code is currently foundation-level with placeholder UI in multiple screens; prioritize existing code behavior over planned-but-missing features.
- `kangal/lib/data/services/` is mostly not implemented yet (`.gitkeep` only); create services there when adding ingestion/sync logic.

## Testing patterns in this repo
- Repository tests use `mockito` mocks for DAOs (see `kangal/test/data/repositories/*_test.dart`).
- Router tests validate onboarding-driven initial route using `SharedPreferences.setMockInitialValues` (see `kangal/test/routing/app_router_test.dart`).
- Theme tests assert constants, contrast checks, and text scaling behavior (see `kangal/test/ui/core/theme_test.dart`).
- If app root class name changes, keep widget tests aligned (`KangalApp`, not template `MyApp`).

## Build, codegen, and validation workflow
- Install deps: `cd kangal && flutter pub get`
- Run app/tests/analyze from `kangal/`:
  - `flutter run`
  - `flutter test`
  - `flutter analyze`
- Regenerate code after editing Drift/Freezed/JSON models:
  - `dart run build_runner build --delete-conflicting-outputs`

## Agent guardrails for edits
- Keep changes minimal and layered; avoid bypassing repositories/DAOs from UI.
- Do not rewrite generated files manually unless the task explicitly asks for it.
- Prefer updating existing route/repository/model patterns rather than introducing a parallel architecture.
