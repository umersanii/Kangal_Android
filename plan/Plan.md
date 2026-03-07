---
goal: Full Implementation of Kangal Personal Finance Android App (M1–M9)
version: 1.0
date_created: 2026-03-06
last_updated: 2026-03-06
owner: Umer Sani
status: 'Planned'
tags: [feature, architecture, migration]
---

# Introduction

![Status: Planned](https://img.shields.io/badge/status-Planned-blue)

This plan covers the complete greenfield implementation of **Kangal**, a local-first, offline-capable personal finance Android app built with Flutter/Dart. Kangal automatically ingests transactions from HBL (via SMS parsing) and NayaPay (via IMAP email parsing), stores them locally in SQLite (Drift), and optionally syncs to Supabase for cloud backup. The plan spans all 9 PRD milestones (M1–M9) in 9 sequential phases. Each task row is an atomic, independently committable unit of work. State management uses `ChangeNotifier` + `provider` (MVVM pattern per Flutter Architecture Recommendations). Open PRD questions are resolved with sensible defaults: 30-minute background email sync, PKR-only, per-user Supabase RLS, background + manual sync triggers, and total PKR amount tracked for card purchases (no separate base currency).

## 1. Requirements & Constraints

- **REQ-001**: Automated transaction ingestion from HBL SMS (3 patterns: card charge, ATM withdrawal, Raast received)
- **REQ-002**: Automated transaction ingestion from NayaPay email (4 types: received, sent P2P, sent to bank, card purchase)
- **REQ-003**: Local-first SQLite (Drift) as single source of truth with optional Supabase cloud sync
- **REQ-004**: Manual transaction entry for cash/unsupported banks
- **REQ-005**: Category tagging with default categories, custom categories, and keyword-based auto-categorisation rules
- **REQ-006**: Dashboard with summary cards, bar chart, donut chart, and period selector
- **REQ-007**: Onboarding wizard covering SMS permission, email setup, and optional Supabase account
- **REQ-008**: Background sync via `workmanager` (30-minute interval for email + Supabase)
- **SEC-001**: Gmail App Password stored in `flutter_secure_storage` (AES-256, Android Keystore)
- **SEC-002**: Supabase auth token stored in `flutter_secure_storage`
- **SEC-003**: No credentials logged or cached in plaintext
- **SEC-004**: Supabase RLS enforces per-user row isolation (`user_id` column on all tables)
- **CON-001**: Android only — minimum API 26 (Android 8.0)
- **CON-002**: PKR only — no multi-currency support in v1
- **CON-003**: English only for v1
- **CON-004**: Target APK size < 25 MB
- **CON-005**: Cold start < 2 seconds, transaction list renders 50 rows in < 500 ms
- **GUD-001**: Follow MVVM pattern — `ChangeNotifier` ViewModels + `provider` for DI
- **GUD-002**: Follow Effective Dart style guidelines (naming, formatting, documentation)
- **GUD-003**: Repository pattern — abstract repository interfaces with concrete implementations
- **GUD-004**: Unidirectional data flow — data updates flow only from data layer to UI layer
- **GUD-005**: Immutable data models generated via `freezed`
- **GUD-006**: Unit tests for every service, repository, and ViewModel; widget tests for views
- **GUD-007**: Use `go_router` for declarative navigation
- **PAT-001**: Deduplication before insert — check `transaction_id` existence; skip silently, log to debug
- **PAT-002**: Subject-line parsing as fast path for NayaPay emails; full body parsing for details
- **PAT-003**: Last-write-wins conflict resolution for Supabase sync based on `updated_at` timestamp

## 2. Implementation Steps

### Implementation Phase 1 — Foundation (M1)

- GOAL-001: Scaffold Flutter project, configure all dependencies, implement Drift database schema, set up Supabase project and tables, create empty app shell with navigation and theming.

| Task | Description | Completed | Date |
| -------- | ----------- | --------- | ---- |
| TASK-001 | Run `flutter create kangal --org com.umersani --platforms android` in the workspace root. Configure `android/app/build.gradle`: `minSdkVersion 26`, `targetSdkVersion 34`, `applicationId "com.umersani.kangal"`. Commit message: `chore: scaffold Flutter project with Android target` | ✅ | 2026-03-07 |
| TASK-002 | Populate `pubspec.yaml` with all dependencies: `drift`, `sqlite3_flutter_libs`, `path_provider`, `path`, `supabase_flutter`, `enough_mail`, `html` (HTML parser), `flutter_secure_storage`, `telephony`, `fl_chart`, `go_router`, `provider`, `workmanager`, `permission_handler`, `intl`, `freezed_annotation`, `json_annotation`. Dev dependencies: `drift_dev`, `build_runner`, `freezed`, `json_serializable`, `flutter_test`, `mockito`, `build_runner`. Run `flutter pub get`. Commit message: `chore: add all project dependencies to pubspec.yaml` | ✅ | 2026-03-07 |
| TASK-003 | Create directory structure under `lib/`: `data/database/tables/`, `data/database/daos/`, `data/models/`, `data/repositories/`, `data/services/`, `ui/core/widgets/`, `ui/dashboard/`, `ui/transactions/`, `ui/add_transaction/`, `ui/settings/`, `ui/settings/email_setup/`, `ui/settings/categories/`, `ui/settings/rules/`, `ui/onboarding/`, `routing/`. Add empty `.gitkeep` files to preserve structure. Commit message: `chore: create MVVM directory structure` | ✅ | 2026-03-07 |
| TASK-004 | Create immutable data models using `freezed` in `lib/data/models/`: `transaction_model.dart` (fields: `id`, `remoteId`, `date`, `amount`, `source`, `type`, `transactionId`, `beneficiary`, `subject`, `categoryId`, `note`, `extra`, `syncedAt`, `updatedAt`, `createdAt`), `category_model.dart` (fields: `id`, `name`, `emoji`, `color`, `isDefault`), `rule_model.dart` (fields: `id`, `keyword`, `categoryId`), `sync_log_model.dart` (fields: `id`, `tableName`, `lastSyncedAt`, `status`). Run `dart run build_runner build --delete-conflicting-outputs`. Commit message: `feat: add freezed immutable data models` | ✅ | 2026-03-07 |
| TASK-005 | Define Drift table classes in `lib/data/database/tables/`: `transactions_table.dart` (`TransactionsTable` extending `Table` — columns match PRD §4.1 schema exactly: `id` IntColumn autoIncrement, `remoteId` TextColumn nullable, `date` TextColumn, `amount` RealColumn, `source` TextColumn, `type` TextColumn nullable, `transactionId` TextColumn nullable unique, `beneficiary` TextColumn nullable, `subject` TextColumn nullable, `categoryId` IntColumn nullable references CategoriesTable, `note` TextColumn nullable, `extra` TextColumn nullable, `syncedAt` DateTimeColumn nullable, `updatedAt` DateTimeColumn withDefault currentDateAndTime, `createdAt` DateTimeColumn withDefault currentDateAndTime), `categories_table.dart`, `rules_table.dart`, `sync_log_table.dart` — columns match PRD §4.2, §4.3, §4.4. Commit message: `feat: define Drift table schemas` | ✅ | 2026-03-07 |
| TASK-006 | Create `lib/data/database/app_database.dart`: `@DriftDatabase(tables: [TransactionsTable, CategoriesTable, RulesTable, SyncLogTable], daos: [TransactionsDao, CategoriesDao, RulesDao, SyncLogDao])` class `AppDatabase extends _$AppDatabase`. Set `schemaVersion = 1`. Implement `LazyDatabase` opener using `path_provider` to get `getApplicationDocumentsDirectory()` and open `kangal.db`. Run `dart run build_runner build --delete-conflicting-outputs`. Commit message: `feat: configure Drift AppDatabase with schema v1` | ✅ | 2026-03-07 |
| TASK-007 | Implement DAOs in `lib/data/database/daos/`: `transactions_dao.dart` (`TransactionsDao` extending `DatabaseAccessor<AppDatabase>` — methods: `getAllTransactions(limit, offset)`, `getTransactionById(id)`, `getTransactionByTransactionId(txnId)`, `insertTransaction(companion)`, `updateTransaction(companion)`, `deleteTransaction(id)`, `getTransactionsByDateRange(start, end)`, `getTransactionsBySource(source)`, `searchTransactions(query)`, `getUnsyncedTransactions()`), `categories_dao.dart` (CRUD + `getDefaultCategories()`, `getCategoryById(id)`), `rules_dao.dart` (CRUD + `getAllRules()`), `sync_log_dao.dart` (`getLastSync(tableName)`, `upsertSyncLog(companion)`). Run code generation. Commit message: `feat: implement Drift DAOs for all tables` | ✅ | 2026-03-07 |
| TASK-008 | Create abstract repository interfaces in `lib/data/repositories/`: `transaction_repository.dart` (abstract class `TransactionRepository` with methods matching DAO surface area plus `getSummary(startDate, endDate)` returning `Future<TransactionSummary>` — a model with `totalSpent`, `totalIncome`, `netBalance`, `transactionCount`), `category_repository.dart` (abstract class `CategoryRepository`), `rule_repository.dart` (abstract class `RuleRepository`). Create concrete implementations: `drift_transaction_repository.dart`, `drift_category_repository.dart`, `drift_rule_repository.dart` — each taking the respective DAO as a constructor parameter. Commit message: `feat: add abstract and Drift-backed repository implementations` | | |
| TASK-009 | Seed default categories on first launch. In `drift_category_repository.dart`, add method `seedDefaultCategories()` that checks if categories table is empty and inserts the 10 defaults: Food & Dining (🍔, #FF5733), Transport (🚗, #3498DB), Utilities (💡, #F1C40F), Shopping (🛍️, #9B59B6), Health (🏥, #2ECC71), Education (📚, #1ABC9C), Entertainment (🎮, #E74C3C), Salary/Income (💰, #27AE60), Transfer (🔄, #8E44AD), Other (📦, #95A5A6) — all with `isDefault = true`. Call from `AppDatabase` migration or app startup. Commit message: `feat: seed 10 default categories on first launch` | | |
| TASK-010 | Configure `go_router` in `lib/routing/app_router.dart`. Define `GoRouter` with routes: `/` (DashboardScreen), `/transactions` (TransactionsScreen), `/transactions/:id` (TransactionDetailScreen), `/add` (AddTransactionScreen), `/settings` (SettingsScreen), `/settings/email` (EmailSetupScreen), `/settings/categories` (CategoriesScreen), `/settings/rules` (RulesScreen), `/onboarding` (OnboardingScreen). Set initial location to `/onboarding` on first launch (use `SharedPreferences` flag `onboarding_complete`), otherwise `/`. Use `StatefulShellRoute` for bottom navigation bar with 3 tabs: Dashboard, Transactions, Settings. Commit message: `feat: configure go_router with all app routes and bottom nav` | | |
| TASK-011 | Create `lib/ui/core/theme.dart`: Define `AppTheme` with `ThemeData` — Material 3, primary color seed, minimum 4.5:1 contrast ratio, support system font scaling. Define color constants for expense (red: `#E74C3C`), income (green: `#27AE60`), source badge colors (HBL: `#006B3F`, NayaPay: `#6C63FF`, Cash: `#95A5A6`). Commit message: `feat: define app theme with Material 3 and accessibility colors` | | |
| TASK-012 | Create `lib/main.dart`: Initialize `WidgetsFlutterBinding`, create `AppDatabase` instance, create all repository instances, wrap app in `MultiProvider` providing `AppDatabase`, `TransactionRepository`, `CategoryRepository`, `RuleRepository` via `Provider`. Create `lib/app.dart` with `MaterialApp.router` using `GoRouter` and `AppTheme`. Create placeholder screens for all routes (empty `Scaffold` with `AppBar` title matching route name). Commit message: `feat: wire up main.dart with provider DI and placeholder screens` | | |
| TASK-013 | Set up Supabase project: Document in a `supabase/README.md` file the exact SQL migration scripts to create tables `transactions`, `categories`, `rules`, `sync_log` in Supabase PostgreSQL — mirroring Drift schema but adding `user_id UUID REFERENCES auth.users(id) NOT NULL` column to each. Include RLS policy SQL: `CREATE POLICY "Users can only access own rows" ON <table> FOR ALL USING (auth.uid() = user_id)`. Include `ALTER TABLE <table> ENABLE ROW LEVEL SECURITY` for each table. Commit message: `feat: add Supabase SQL migration scripts with RLS policies` | | |

### Implementation Phase 2 — HBL SMS Parser (M2)

- GOAL-002: Implement SMS permission flow, parse 3 HBL SMS patterns (card charge, ATM withdrawal, Raast received), and import transactions into the local database with deduplication.

| Task | Description | Completed | Date |
| -------- | ----------- | --------- | ---- |
| TASK-014 | Create `lib/data/services/hbl_sms_service.dart`: class `HblSmsService` with method `parseHblSms(String smsBody) → TransactionModel?`. Implement 3 regex patterns: **Pattern A** (Debit Card): regex `r"HBL Debit Card.*?PKR\s*([\d,]+\.?\d*)\s*on\s*(\d{2}/\d{2}/\d{4}\s+\d{2}:\d{2}:\d{2})"` → amount negative, type `card_charge`, beneficiary null, transactionId = SHA-256 hash of SMS body. **Pattern B** (ATM): regex `r"HBL A/C.*?debited with PKR\s*([\d,]+\.?\d*)\s*on\s*(\d{2}/\d{2}/\d{4}\s+\d{2}:\d{2}:\d{2}).*?for\s+(.+)\."` → amount negative, type `atm_withdrawal`, beneficiary = "ATM Cash Withdrawal", transactionId = SHA-256 hash. **Pattern C** (Raast Received): regex `r"PKR\s*([\d,]+\.?\d*)\s*received from\s+(.+?)\s+A/C.*?on\s*(\d{2}/\d{2}/\d{4}\s+\d{2}:\d{2}:\d{2}).*?TXN ID\s+(\S+)"` → amount positive, type `raast_received`, beneficiary = sender name, transactionId = TXN ID value. Parse date with `DateFormat('dd/MM/yyyy HH:mm:ss')`. Set `source = "HBL"`, `subject = smsBody`. Return null if no pattern matches. Commit message: `feat: implement HBL SMS parser with 3 regex patterns` | | |
| TASK-015 | Write unit tests in `test/data/services/hbl_sms_service_test.dart`: Test each of the 3 SMS patterns using the exact sample messages from `HBL_SMS/messages.txt`. Assert correct amount (sign), date parsing, beneficiary extraction, transactionId, source, and type for each. Test malformed/unknown SMS returns null. Test edge cases: amounts with commas, amounts without decimals, multi-line SMS. Commit message: `test: add unit tests for HBL SMS parser (3 patterns)` | | |
| TASK-016 | Create `lib/data/services/sms_permission_service.dart`: class `SmsPermissionService` using `permission_handler` package. Methods: `requestSmsPermission() → Future<bool>` (requests `Permission.sms`), `isSmsPermissionGranted() → Future<bool>`, `openAppSettings()`. Handle all `PermissionStatus` states (granted, denied, permanentlyDenied). Commit message: `feat: add SMS permission service using permission_handler` | | |
| TASK-017 | Create `lib/data/services/sms_inbox_service.dart`: class `SmsInboxService` using `telephony` package. Method `getHblMessages({int daysBack = 90}) → Future<List<SmsMessage>>` — queries inbox filtering by sender containing "HBL" (case-insensitive) and date >= 90 days ago. Method `listenForNewSms(void Function(SmsMessage) onMessage)` — registers background/foreground SMS listener, filters for HBL sender, invokes callback. Commit message: `feat: add SMS inbox reader and real-time listener service` | | |
| TASK-018 | Create `lib/data/repositories/sms_import_repository.dart`: abstract class `SmsImportRepository` with methods `importHistoricalSms() → Future<int>` (returns count of new transactions imported) and `startRealtimeListener()`. Create `lib/data/repositories/sms_import_repository_impl.dart`: concrete implementation taking `SmsInboxService`, `HblSmsService`, and `TransactionRepository` as constructor dependencies. `importHistoricalSms()`: gets HBL messages from inbox, parses each with `HblSmsService`, checks dedup via `TransactionRepository.getByTransactionId()`, inserts new ones, returns count. Applies auto-categorisation rules from `RuleRepository` on each insert. `startRealtimeListener()`: delegates to `SmsInboxService.listenForNewSms`, parses + dedup + inserts. Commit message: `feat: implement SMS import repository with dedup and auto-categorisation` | | |
| TASK-019 | Write unit tests in `test/data/repositories/sms_import_repository_test.dart`: Create fakes for `SmsInboxService`, `HblSmsService`, `TransactionRepository`, `RuleRepository`. Test: importing 3 unique messages inserts 3 records; importing a duplicate (same transactionId) skips it; auto-categorisation rule matches apply correct categoryId; empty inbox returns 0. Commit message: `test: add unit tests for SMS import repository` | | |
| TASK-020 | Register `SmsPermissionService`, `SmsInboxService`, `HblSmsService`, and `SmsImportRepository` in `MultiProvider` in `lib/main.dart`. Commit message: `chore: register SMS services and repository in provider DI` | | |

### Implementation Phase 3 — NayaPay Email Parser (M3)

- GOAL-003: Implement IMAP email connection, parse all 4 NayaPay email types (received, sent P2P, sent to bank, card purchase) from subject line and HTML body, and import transactions with deduplication and manual refresh.

| Task | Description | Completed | Date |
| -------- | ----------- | --------- | ---- |
| TASK-021 | Create `lib/data/services/secure_storage_service.dart`: class `SecureStorageService` wrapping `FlutterSecureStorage`. Methods: `saveEmailCredentials(String email, String appPassword)`, `getEmailCredentials() → Future<({String email, String appPassword})?>`, `deleteEmailCredentials()`, `saveSupabaseToken(String token)`, `getSupabaseToken()`, `deleteSupabaseToken()`, `hasEmailCredentials() → Future<bool>`. All keys prefixed with `kangal_`. Commit message: `feat: add secure storage service for credentials management` | | |
| TASK-022 | Create `lib/data/services/imap_service.dart`: class `ImapService` using `enough_mail` package. Constructor takes email and appPassword. Methods: `connect() → Future<void>` (connects to `imap.gmail.com:993` with SSL), `disconnect()`, `fetchNayaPayEmails({int daysBack = 90}) → Future<List<MimeMessage>>` (selects INBOX, searches for `FROM service@nayapay.com` with date filter `SINCE <date>`, fetches full messages), `testConnection() → Future<bool>` (attempts connect + disconnect, returns success/failure). Commit message: `feat: add IMAP service for Gmail connection using enough_mail` | | |
| TASK-023 | Create `lib/data/services/nayapay_email_service.dart`: class `NayaPayEmailService`. Main method: `parseEmail(MimeMessage message) → TransactionModel?`. Implement subject-line parsing (fast path) using 3 regex patterns: `r"You got Rs\.\s*([\d,]+(?:\.\d+)?)\s*from\s+(.+?)\s*🎉"` → income, `r"You sent Rs\.\s*([\d,]+(?:\.\d+)?)\s*to\s+(.+?)\s*💸"` → expense, `r"You spent Rs\.\s*([\d,]+(?:\.\d+)?)\s*at\s+(.+?)\s*💳"` → expense. Extract amount and beneficiary/merchant from subject. Commit message: `feat: implement NayaPay subject-line parser (fast path)` | | |
| TASK-024 | Extend `NayaPayEmailService` with body parsing. Add private methods: `_parseType1Plaintext(String plaintext)` — splits plaintext by whitespace to extract `[amount, name, txnId, date, senderTag]`. `_parseType2Plaintext(String plaintext)` — extracts `[amount, name, txnId, date, senderTag, receiverTag]`. `_parseType3Html(String html)` — uses `html` package to parse HTML, extracts beneficiary name, destination bank, masked account, channel (Raast), date, transaction ID via CSS selectors or regex on HTML structure. `_parseType4Html(String html)` — extracts merchant + location, card info (`Visa ●●●●0268`), merchant category, fees breakdown (base, intl fees, SST, FX), total amount, transaction ID. Stores extra data as JSON in `extra` field. For Types 3 & 4, fallback from plaintext to HTML when plaintext is empty. Date parsing uses `DateFormat('dd MMM yyyy, hh:mm a')` for plaintext dates and appropriate format for HTML dates. Commit message: `feat: implement NayaPay full body parser (4 email types with HTML fallback)` | | |
| TASK-025 | Write unit tests in `test/data/services/nayapay_email_service_test.dart`: Load the 4 real `.eml` files from `nayapay_emails/` directory as test fixtures. For each email type, assert: correct amount (sign), beneficiary/merchant, transactionId, date, source (`NayaPay`), type (`received`/`sent_p2p`/`sent_bank`/`card_purchase`), and extra JSON fields where applicable. Test subject-line-only parsing. Test HTML fallback for Types 3 & 4 when plaintext is empty. Test malformed email returns null. Commit message: `test: add unit tests for NayaPay email parser (all 4 types)` | | |
| TASK-026 | Create `lib/data/repositories/email_import_repository.dart`: abstract class `EmailImportRepository` with methods `importEmails() → Future<int>`, `testConnection() → Future<bool>`. Create `lib/data/repositories/email_import_repository_impl.dart`: concrete implementation taking `ImapService`, `NayaPayEmailService`, `TransactionRepository`, `RuleRepository`, `SecureStorageService`. `importEmails()`: reads credentials from secure storage, connects via IMAP, fetches NayaPay emails (last 90 days), parses each, deduplicates by transactionId, applies auto-categorisation rules, inserts new transactions, disconnects, returns count. `testConnection()`: delegates to `ImapService.testConnection()`. Commit message: `feat: implement email import repository with dedup and auto-categorisation` | | |
| TASK-027 | Write unit tests in `test/data/repositories/email_import_repository_test.dart`: Create fakes for all dependencies. Test: importing 4 unique emails inserts 4 records; duplicate emails are skipped; credentials missing returns 0 gracefully; IMAP connection failure throws/handles gracefully; auto-categorisation rules apply. Commit message: `test: add unit tests for email import repository` | | |
| TASK-028 | Configure `workmanager` for background email sync. Create `lib/data/services/background_sync_service.dart`: register a periodic task `nayapay_email_sync` with `Workmanager` — frequency 30 minutes, constraints: `NetworkType.connected`. The callback function creates necessary dependencies and calls `EmailImportRepository.importEmails()`. Initialize `Workmanager` in `main.dart`. Add `<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>` to `AndroidManifest.xml` for workmanager. Commit message: `feat: configure workmanager for 30-min background email sync` | | |
| TASK-029 | Register `SecureStorageService`, `ImapService`, `NayaPayEmailService`, `EmailImportRepository`, and `BackgroundSyncService` in `MultiProvider` in `lib/main.dart`. `ImapService` should be created lazily (only when credentials exist). Commit message: `chore: register email services and repository in provider DI` | | |

### Implementation Phase 4 — Dashboard (M4)

- GOAL-004: Implement the dashboard screen with summary cards (total spent, total income, net balance, transaction count), bar chart (daily/weekly spend), donut chart (category breakdown), and period selector.

| Task | Description | Completed | Date |
| -------- | ----------- | --------- | ---- |
| TASK-030 | Create `lib/ui/dashboard/dashboard_view_model.dart`: class `DashboardViewModel extends ChangeNotifier`. Fields: `TransactionSummary? summary`, `List<DailySpend> dailySpend`, `List<CategorySpend> categorySpend`, `DateRange selectedPeriod`, `bool isLoading`. Enum `PeriodPreset { thisWeek, thisMonth, lastMonth, allTime }`. Method `selectPeriod(PeriodPreset preset)` computes `DateRange` and calls `loadDashboardData()`. Method `loadDashboardData()`: queries `TransactionRepository.getSummary(start, end)`, `TransactionRepository.getDailySpend(start, end)`, `TransactionRepository.getCategorySpend(start, end)`, sets fields and calls `notifyListeners()`. Constructor takes `TransactionRepository`, loads `thisMonth` by default. Commit message: `feat: implement DashboardViewModel with summary, chart data, and period selection` | | |
| TASK-031 | Add required repository methods. In `TransactionRepository` (abstract + Drift impl): `getDailySpend(DateTime start, DateTime end) → Future<List<DailySpend>>` — groups transactions by date, sums negative amounts per day. `getCategorySpend(DateTime start, DateTime end) → Future<List<CategorySpend>>` — groups negative-amount transactions by categoryId, sums amounts, joins category name/emoji/color. Create data classes `DailySpend` (date, totalSpent) and `CategorySpend` (categoryId, categoryName, emoji, color, totalSpent) in `lib/data/models/`. Commit message: `feat: add getDailySpend and getCategorySpend to transaction repository` | | |
| TASK-032 | Create `lib/ui/core/widgets/period_selector.dart`: a `Row` of `ChoiceChip` widgets for This Week / This Month / Last Month / All Time. Takes `PeriodPreset current` and `ValueChanged<PeriodPreset> onChanged` callback. Commit message: `feat: add PeriodSelector reusable widget` | | |
| TASK-033 | Create `lib/ui/dashboard/widgets/summary_cards.dart`: a horizontal `Row` or `Wrap` of 4 cards — Total Spent (red, formatted as `Rs. X,XXX`), Total Income (green), Net Balance (dynamic color), Transaction Count. Takes `TransactionSummary` as input. Use `intl` `NumberFormat` for PKR formatting. Commit message: `feat: add dashboard summary cards widget` | | |
| TASK-034 | Create `lib/ui/dashboard/widgets/spend_bar_chart.dart`: `fl_chart` `BarChart` displaying daily spend over the selected period. X-axis = date labels, Y-axis = PKR amount. Takes `List<DailySpend>` as input. Style bars with expense color from theme. Commit message: `feat: add daily spend bar chart widget using fl_chart` | | |
| TASK-035 | Create `lib/ui/dashboard/widgets/category_donut_chart.dart`: `fl_chart` `PieChart` (donut style) showing spending breakdown by category. Each section colored by category color, with emoji legend. Takes `List<CategorySpend>` as input. Show percentage labels on sections. Commit message: `feat: add category spending donut chart widget using fl_chart` | | |
| TASK-036 | Implement `lib/ui/dashboard/dashboard_screen.dart`: `Consumer` widget using `Provider.of<DashboardViewModel>`. Layout: `SingleChildScrollView` → `Column` containing `PeriodSelector` at top, `SummaryCards`, `SpendBarChart`, `CategoryDonutChart`. Show `CircularProgressIndicator` while `isLoading`. Show empty state message if no transactions exist. Commit message: `feat: implement dashboard screen composing summary cards and charts` | | |
| TASK-037 | Write widget tests in `test/ui/dashboard/dashboard_screen_test.dart`: Mock `DashboardViewModel` with sample data. Assert: 4 summary cards render with correct values, bar chart renders, donut chart renders, period selector changes trigger ViewModel method call. Test empty state. Commit message: `test: add widget tests for dashboard screen` | | |

### Implementation Phase 5 — Categories & Auto-Rules (M5)

- GOAL-005: Implement category management (view defaults, create custom, edit, delete with reassignment to Other) and keyword-based auto-categorisation rules (CRUD + automatic application on transaction import).

| Task | Description | Completed | Date |
| -------- | ----------- | --------- | ---- |
| TASK-038 | Create `lib/ui/settings/categories/categories_view_model.dart`: class `CategoriesViewModel extends ChangeNotifier`. Fields: `List<CategoryModel> categories`, `bool isLoading`. Methods: `loadCategories()`, `addCategory(name, emoji, color)`, `updateCategory(id, name, emoji, color)`, `deleteCategory(id)` — on delete, calls `TransactionRepository.reassignCategory(oldId, otherCategoryId)` then deletes. Prevents deletion of default categories (where `isDefault == true`). Commit message: `feat: implement CategoriesViewModel with CRUD and safe deletion` | | |
| TASK-039 | Add method `reassignCategory(int oldCategoryId, int newCategoryId) → Future<int>` to `TransactionRepository` abstract interface and Drift implementation — updates all transactions with `categoryId == oldCategoryId` to `newCategoryId`, returns count of affected rows. Commit message: `feat: add reassignCategory method to transaction repository` | | |
| TASK-040 | Create `lib/ui/settings/categories/categories_screen.dart`: `ListView` of category tiles — each showing emoji, name, color swatch. Default categories show a lock icon (non-deletable). Custom categories show edit/delete icons. FAB to add new category. Add/edit dialog: `TextField` for name, color picker (simple grid of preset colors), emoji text field. Delete confirmation dialog showing count of transactions that will be reassigned to "Other". Commit message: `feat: implement categories management screen with add/edit/delete` | | |
| TASK-041 | Create `lib/ui/settings/rules/rules_view_model.dart`: class `RulesViewModel extends ChangeNotifier`. Fields: `List<RuleModel> rules`, `List<CategoryModel> categories`, `bool isLoading`. Methods: `loadRules()`, `addRule(keyword, categoryId)`, `updateRule(id, keyword, categoryId)`, `deleteRule(id)`, `applyRulesToAllTransactions()` (iterates all transactions, applies keyword matching against beneficiary, updates categoryId where matched). Takes `RuleRepository`, `CategoryRepository`, `TransactionRepository`. Commit message: `feat: implement RulesViewModel with CRUD and bulk rule application` | | |
| TASK-042 | Create `lib/ui/settings/rules/rules_screen.dart`: `ListView` of rule tiles — each showing keyword and target category name/emoji. FAB to add new rule. Add/edit dialog: `TextField` for keyword, `DropdownButton` for category selection. Delete with confirmation. Button: "Apply Rules to All Transactions" triggers bulk application with progress indicator and result snackbar showing count of recategorised transactions. Commit message: `feat: implement auto-categorisation rules management screen` | | |
| TASK-043 | Create `lib/data/services/auto_categorisation_service.dart`: class `AutoCategorisationService` with method `applyCategoryRules(TransactionModel transaction, List<RuleModel> rules) → int?` — iterates rules, performs case-insensitive `contains` match of `rule.keyword` against `transaction.beneficiary`. Returns first matching `rule.categoryId`, or null if no match. This service is used by `SmsImportRepository` and `EmailImportRepository` during import. Commit message: `feat: add auto-categorisation service for keyword-based rule matching` | | |
| TASK-044 | Write unit tests: `test/data/services/auto_categorisation_service_test.dart` (keyword matching, case insensitivity, no match returns null, first match wins), `test/ui/settings/categories/categories_view_model_test.dart` (CRUD operations, default category deletion prevented, reassignment on delete), `test/ui/settings/rules/rules_view_model_test.dart` (CRUD operations, bulk apply). Commit message: `test: add unit tests for categories, rules, and auto-categorisation` | | |

### Implementation Phase 6 — Manual Transaction Entry (M6)

- GOAL-006: Implement the manual transaction entry form with validation, category selection, and immediate persistence to the local database.

| Task | Description | Completed | Date |
| -------- | ----------- | --------- | ---- |
| TASK-045 | Create `lib/ui/add_transaction/add_transaction_view_model.dart`: class `AddTransactionViewModel extends ChangeNotifier`. Fields: `double? amount`, `DateTime selectedDate` (default: now), `String? beneficiary`, `int? categoryId`, `String? note`, `String source` (default: "Cash"), `bool isSaving`, `String? errorMessage`, `List<CategoryModel> categories`. Method `saveTransaction() → Future<bool>`: validates amount != 0 and date not in future, creates `TransactionModel` with source = "Cash" or "Other", type = "manual", transactionId = null, calls `TransactionRepository.insert()`, applies auto-categorisation if categoryId not manually set, returns true on success. Method `loadCategories()`. Takes `TransactionRepository`, `CategoryRepository`, `AutoCategorisationService`, `RuleRepository`. Commit message: `feat: implement AddTransactionViewModel with validation and save` | | |
| TASK-046 | Create `lib/ui/add_transaction/add_transaction_screen.dart`: `Form` with `GlobalKey<FormState>`. Fields: amount `TextFormField` (number keyboard, validator: non-zero), date/time picker button (shows current selection, opens `showDatePicker` + `showTimePicker`), beneficiary `TextFormField` (optional), category `DropdownButtonFormField` populated from ViewModel categories, note `TextFormField` (multiline, optional), source `SegmentedButton` with Cash / Other. Save button calls `ViewModel.saveTransaction()`, shows `SnackBar` on success and pops route, shows error message on validation failure. Commit message: `feat: implement manual transaction entry screen with form validation` | | |
| TASK-047 | Write tests: `test/ui/add_transaction/add_transaction_view_model_test.dart` (valid save succeeds, zero amount fails, future date fails, auto-categorisation applies when no category selected), widget test `test/ui/add_transaction/add_transaction_screen_test.dart` (form renders all fields, validation messages appear, successful save navigates back). Commit message: `test: add unit and widget tests for manual transaction entry` | | |

### Implementation Phase 7 — Transaction List & Detail (M4 supplement)

- GOAL-007: Implement the full transaction list screen with infinite scroll, filtering, search, and the transaction detail bottom sheet with edit and delete capabilities.

| Task | Description | Completed | Date |
| -------- | ----------- | --------- | ---- |
| TASK-048 | Create `lib/ui/transactions/transactions_view_model.dart`: class `TransactionsViewModel extends ChangeNotifier`. Fields: `List<TransactionModel> transactions`, `bool isLoading`, `bool hasMore`, `int _offset`, `String? searchQuery`, `String? sourceFilter`, `int? categoryFilter`, `DateRange? dateFilter`. Methods: `loadTransactions()` (fetches 50, sets `_offset`), `loadMore()` (fetches next 50, appends, increments `_offset`, sets `hasMore = false` if < 50 returned), `setSearchQuery(String?)`, `setSourceFilter(String?)`, `setCategoryFilter(int?)`, `setDateFilter(DateRange?)` — each resets `_offset` to 0 and calls `loadTransactions()`. Takes `TransactionRepository`. Commit message: `feat: implement TransactionsViewModel with pagination, filters, and search` | | |
| TASK-049 | Create `lib/ui/core/widgets/transaction_card.dart`: a `Card` widget displaying: amount (red if negative, green if positive, formatted `Rs. X,XXX.XX`), beneficiary name, date (formatted `dd MMM yyyy, hh:mm a`), source badge (`Chip` with HBL/NayaPay/Cash colored per theme), category chip (emoji + name). Takes `TransactionModel` and `VoidCallback onTap`. Commit message: `feat: add TransactionCard reusable widget` | | |
| TASK-050 | Create `lib/ui/core/widgets/source_badge.dart` and `lib/ui/core/widgets/category_chip.dart`: Small presentational widgets. `SourceBadge` displays colored `Chip` — HBL green, NayaPay purple, Cash grey. `CategoryChip` displays emoji + category name in a compact `Chip`. Commit message: `feat: add SourceBadge and CategoryChip reusable widgets` | | |
| TASK-051 | Create `lib/ui/transactions/transactions_screen.dart`: `Scaffold` with `AppBar` containing search icon (toggles `TextField` for search input). Below AppBar: horizontal `FilterChip` row for source filter (All, HBL, NayaPay, Cash), date range presets (Today, This Week, This Month, Custom — custom opens `showDateRangePicker`). Body: `ListView.builder` with `ScrollController` detecting when user scrolls to bottom → calls `ViewModel.loadMore()`. Shows `CircularProgressIndicator` at list bottom when loading more. Empty state when no transactions found. Commit message: `feat: implement transactions list screen with infinite scroll and filters` | | |
| TASK-052 | Create `lib/ui/transactions/transaction_detail_view_model.dart`: class `TransactionDetailViewModel extends ChangeNotifier`. Fields: `TransactionModel? transaction`, `List<CategoryModel> categories`, `bool isLoading`, `bool isDeleting`. Methods: `loadTransaction(int id)`, `updateCategory(int categoryId)` → updates via repository + `notifyListeners()`, `updateNote(String note)` → updates via repository, `deleteTransaction()` → shows confirmation, deletes via repository, returns `true` on success. Takes `TransactionRepository`, `CategoryRepository`. Commit message: `feat: implement TransactionDetailViewModel with edit and delete` | | |
| TASK-053 | Create `lib/ui/transactions/transaction_detail_screen.dart`: Bottom sheet launched via `showModalBottomSheet` from transaction list. Displays all fields: amount (large, colored), beneficiary, date/time, source badge, category (editable dropdown), type, transactionId, raw subject/SMS body (expandable text), note (editable `TextField`), extra JSON fields formatted as key-value pairs. Edit category: `DropdownButton` that calls `ViewModel.updateCategory()` on change. Edit note: `TextField` with save icon that calls `ViewModel.updateNote()`. Delete button at bottom with red styling → confirmation `AlertDialog` → on confirm, deletes and pops sheet. Commit message: `feat: implement transaction detail bottom sheet with edit and delete` | | |
| TASK-054 | Write tests: `test/ui/transactions/transactions_view_model_test.dart` (pagination loads 50, loadMore appends, filters reset offset, search filters results), `test/ui/transactions/transaction_detail_view_model_test.dart` (load, update category, update note, delete), widget test for `TransactionCard`. Commit message: `test: add unit and widget tests for transactions list and detail` | | |

### Implementation Phase 8 — Supabase Sync (M7)

- GOAL-008: Implement Supabase authentication (email/password sign-up), bidirectional sync (upload unsynced + download new), last-write-wins conflict resolution, background sync via workmanager, and sync status UI in Settings.

| Task | Description | Completed | Date |
| -------- | ----------- | --------- | ---- |
| TASK-055 | Create `lib/data/services/supabase_auth_service.dart`: class `SupabaseAuthService`. Methods: `signUp(String email, String password) → Future<AuthResponse>`, `signIn(String email, String password) → Future<AuthResponse>`, `signOut()`, `isAuthenticated() → Future<bool>`, `getCurrentUserId() → String?`. Uses `Supabase.instance.client.auth`. Stores/retrieves session via `flutter_secure_storage`. Commit message: `feat: implement Supabase auth service with sign-up and sign-in` | | |
| TASK-056 | Create `lib/data/services/supabase_sync_service.dart`: class `SupabaseSyncService`. Takes `SupabaseClient`, `TransactionsDao`, `CategoriesDao`, `RulesDao`, `SyncLogDao`. Method `syncAll() → Future<SyncResult>` orchestrates full sync: (1) Upload: query local records where `syncedAt IS NULL` or `updatedAt > syncedAt`, upsert to Supabase tables with `user_id` attached, on success set `syncedAt = DateTime.now()` locally. (2) Download: query `sync_log` for `last_synced_at`, pull Supabase records where `updated_at > last_synced_at`, upsert locally matching on `remote_id`, apply last-write-wins by comparing `updatedAt` timestamps. (3) Update `sync_log` entries. Return `SyncResult` (uploaded count, downloaded count, conflicts resolved count, success bool). Commit message: `feat: implement Supabase bidirectional sync service with last-write-wins` | | |
| TASK-057 | Create `lib/data/models/sync_result.dart` (freezed): fields `int uploaded`, `int downloaded`, `int conflictsResolved`, `bool success`, `String? errorMessage`. Commit message: `feat: add SyncResult data model` | | |
| TASK-058 | Create `lib/data/repositories/sync_repository.dart`: abstract class `SyncRepository` with methods `syncNow() → Future<SyncResult>`, `getLastSyncTime() → Future<DateTime?>`, `hasUnsyncedChanges() → Future<bool>`. Create `lib/data/repositories/sync_repository_impl.dart`: concrete implementation using `SupabaseSyncService` and `SyncLogDao`. `hasUnsyncedChanges()` checks for transactions where `syncedAt IS NULL` or `updatedAt > syncedAt`. Commit message: `feat: implement sync repository with sync status queries` | | |
| TASK-059 | Extend `BackgroundSyncService` (from TASK-028) to also run Supabase sync. Add periodic task `supabase_sync` with 30-minute frequency, constraint: `NetworkType.connected`. The callback creates `SupabaseSyncService` and calls `syncAll()`. Only runs if user is authenticated (check via `SupabaseAuthService.isAuthenticated()`). Commit message: `feat: add Supabase background sync to workmanager schedule` | | |
| TASK-060 | Create `lib/ui/settings/settings_view_model.dart`: class `SettingsViewModel extends ChangeNotifier`. Fields: `DateTime? lastSyncTime`, `bool hasUnsyncedChanges`, `bool isSyncing`, `bool isAuthenticated`, `SyncResult? lastSyncResult`. Methods: `loadSyncStatus()`, `syncNow()` (calls `SyncRepository.syncNow()`, updates fields, calls `notifyListeners()`), `loadAuthStatus()`. Takes `SyncRepository`, `SupabaseAuthService`. Commit message: `feat: implement SettingsViewModel with sync status and manual sync` | | |
| TASK-061 | Update `lib/ui/settings/settings_screen.dart`: Replace placeholder with full settings UI. Sections: **Account** — shows Supabase auth status (email or "Not signed in"), sign-up/sign-in button navigating to auth screen. **Sync** — shows last sync timestamp (formatted), "Sync Now" button with loading indicator, badge showing count of unsynced changes, last sync result summary. **Data Sources** — SMS setup status (permission granted: yes/no), Email setup status (credentials configured: yes/no) with navigation to setup screens. **Categories** — navigate to `/settings/categories`. **Auto-Rules** — navigate to `/settings/rules`. **About** — app version, "Kangal v1.0". Commit message: `feat: implement full settings screen with sync status and navigation` | | |
| TASK-062 | Create `lib/ui/settings/supabase_auth_screen.dart`: Sign-up / Sign-in form. Two tabs: Sign Up (email + password + confirm password) and Sign In (email + password). Validates email format and password minimum 8 chars. On submit, calls `SupabaseAuthService.signUp/signIn()`. Shows success snackbar and navigates back. Shows error message on failure. Commit message: `feat: implement Supabase auth screen with sign-up and sign-in` | | |
| TASK-063 | Write tests: `test/data/services/supabase_sync_service_test.dart` (upload unsynced records, download new records, conflict resolution picks latest `updatedAt`, empty sync returns zeros), `test/data/repositories/sync_repository_test.dart` (hasUnsyncedChanges, getLastSyncTime), `test/ui/settings/settings_view_model_test.dart` (syncNow updates fields, loadSyncStatus). Commit message: `test: add unit tests for Supabase sync service, repository, and settings ViewModel` | | |

### Implementation Phase 9 — Onboarding (M8)

- GOAL-009: Implement the first-launch onboarding wizard with step-by-step setup for SMS permission, email credentials, optional Supabase account, and completion screen showing import count.

| Task | Description | Completed | Date |
| -------- | ----------- | --------- | ---- |
| TASK-064 | Create `lib/ui/onboarding/onboarding_view_model.dart`: class `OnboardingViewModel extends ChangeNotifier`. Fields: `int currentStep` (0–4), `bool smsPermissionGranted`, `bool emailConfigured`, `bool supabaseConfigured`, `int importedTransactionCount`, `bool isImporting`. Methods: `requestSmsPermission()` → delegates to `SmsPermissionService`, sets `smsPermissionGranted`, if granted triggers `SmsImportRepository.importHistoricalSms()` and sets `importedTransactionCount`. `saveEmailCredentials(email, password)` → saves via `SecureStorageService`, tests connection via `EmailImportRepository.testConnection()`, if success sets `emailConfigured`, triggers `EmailImportRepository.importEmails()`, adds to `importedTransactionCount`. `skipStep()` → increments `currentStep`. `completeOnboarding()` → writes `onboarding_complete = true` to `SharedPreferences`, navigates to `/`. Takes all necessary services/repositories. Commit message: `feat: implement OnboardingViewModel with step-by-step setup logic` | | |
| TASK-065 | Create `lib/ui/onboarding/onboarding_screen.dart`: `PageView` with 5 pages. **Page 0 (Welcome):** Kangal logo/illustration, brief intro text ("Track your spending automatically from HBL and NayaPay"), "Get Started" button → next page. **Page 1 (HBL SMS):** Explanation of SMS permission and why it's needed, "Grant SMS Permission" button → calls `ViewModel.requestSmsPermission()`, shows result (granted/denied), "Skip" button. **Page 2 (NayaPay Email):** Explanation of Gmail App Password, step-by-step guide text (1. Go to Google Account → Security → 2-Step Verification → App Passwords, 2. Generate password, 3. Enter below), email `TextField` + app password `TextField` (obscured), "Connect" button → calls `ViewModel.saveEmailCredentials()`, shows connection test result, "Skip" button. **Page 3 (Cloud Backup):** Explanation of Supabase sync, "Sign Up" button navigating to auth screen, "Skip" button. **Page 4 (Done):** Checkmark animation, "X transactions imported!" message, "Go to Dashboard" button → calls `ViewModel.completeOnboarding()`. Page indicator dots at bottom. Commit message: `feat: implement onboarding wizard with 5-step PageView` | | |
| TASK-066 | Add conditional routing in `lib/routing/app_router.dart`: on app start, check `SharedPreferences` for `onboarding_complete` flag. If false or absent, redirect to `/onboarding`. If true, redirect to `/`. Also add a "Re-run Setup" option in Settings that navigates to `/onboarding`. Commit message: `feat: add conditional onboarding redirect in router` | | |
| TASK-067 | Create a persistent setup prompt banner widget `lib/ui/core/widgets/setup_banner.dart`: displayed on Dashboard and Transactions screens when both SMS permission is denied AND email credentials are not configured. Shows message "Set up your banks to start tracking automatically" with "Set Up" button navigating to Settings. Banner uses `SecureStorageService.hasEmailCredentials()` and `SmsPermissionService.isSmsPermissionGranted()` to determine visibility. Commit message: `feat: add persistent setup prompt banner for unconfigured users` | | |
| TASK-068 | Create `lib/ui/settings/email_setup/email_setup_view_model.dart` and `lib/ui/settings/email_setup/email_setup_screen.dart`: Standalone email setup accessible from Settings. ViewModel: `email`, `appPassword`, `isTestingConnection`, `connectionTestResult`, `isSaving`. Methods: `testConnection()`, `saveCredentials()`, `deleteCredentials()`. Screen: same fields as onboarding page 2 but standalone — email field, password field, "Test Connection" button with result indicator, "Save" button, "Remove Credentials" button (with confirmation). Commit message: `feat: implement standalone email setup screen in settings` | | |
| TASK-069 | Write tests: `test/ui/onboarding/onboarding_view_model_test.dart` (step progression, SMS permission grant triggers import, email save triggers import and adds to count, skip advances step, completeOnboarding sets SharedPreferences flag), widget test `test/ui/onboarding/onboarding_screen_test.dart` (5 pages render, navigation between pages, skip buttons work). Commit message: `test: add unit and widget tests for onboarding flow` | | |

### Implementation Phase 10 — Polish & QA (M9)

- GOAL-010: Perform UI polish, edge case handling, performance optimization, and final integration testing to prepare for release.

| Task | Description | Completed | Date |
| -------- | ----------- | --------- | ---- |
| TASK-070 | Add loading states and error handling to all screens. Every ViewModel should expose `String? errorMessage` field set on caught exceptions. Every screen should show a user-friendly error `SnackBar` or inline message when `errorMessage` is non-null. Add `try-catch` blocks around all repository calls in ViewModels. Specific error messages for: IMAP connection failure ("Could not connect to Gmail. Check your credentials."), SMS permission denied ("SMS access required for HBL tracking."), Supabase sync failure ("Sync failed. Will retry automatically."). Commit message: `feat: add comprehensive error handling and user-friendly error messages` | | |
| TASK-071 | Add pull-to-refresh on Transactions screen (`RefreshIndicator` wrapping `ListView`) that triggers fresh data load. Add pull-to-refresh on Dashboard that reloads summary data. Add "Refresh Emails" button in Settings that triggers `EmailImportRepository.importEmails()` and shows snackbar with count. Commit message: `feat: add pull-to-refresh on transactions and dashboard screens` | | |
| TASK-072 | Optimize transaction list performance: ensure Drift queries use proper indexes (add `@TableIndex` on `transactions` table for `date`, `source`, `categoryId`, `transactionId` columns). Verify pagination loads exactly 50 rows. Profile `ListView.builder` to ensure no unnecessary rebuilds — use `const` constructors where possible, `Selector` from `provider` to rebuild only affected widgets. Commit message: `perf: add database indexes and optimize transaction list rendering` | | |
| TASK-073 | Implement PKR currency formatting utility: `lib/ui/core/utils/currency_formatter.dart` — function `formatPkr(double amount) → String` that returns `Rs. X,XXX.XX` with proper thousand separators using `intl` `NumberFormat.currency(locale: 'en_PK', symbol: 'Rs. ', decimalDigits: 2)`. Use consistently across all screens. Commit message: `feat: add PKR currency formatter utility and apply across all screens` | | |
| TASK-074 | Accessibility pass: verify all interactive elements have semantic labels (`Semantics` widget or `tooltip`). Verify minimum 4.5:1 contrast ratio on all text against backgrounds. Verify app respects `MediaQuery.textScaleFactor` for system font scaling. Test with Android TalkBack. Commit message: `fix: accessibility improvements — semantic labels, contrast, and font scaling` | | |
| TASK-075 | Create integration test in `integration_test/app_test.dart`: Full flow — launch app → onboarding wizard (skip all steps) → navigate to dashboard (empty state) → add manual transaction → verify it appears in transaction list → tap transaction → view detail → edit category → delete transaction → verify removed from list → navigate to settings → verify sync status shows "Not signed in". Use `IntegrationTestWidgetsFlutterBinding`. Commit message: `test: add end-to-end integration test for core user flow` | | |
| TASK-076 | Final cleanup: ensure all files have proper `///` doc comments on public classes and methods. Run `dart format .` on entire project. Run `dart analyze` and fix all warnings/infos. Update `README.md` with project description, setup instructions (Flutter version, `flutter pub get`, `dart run build_runner build`), architecture overview diagram (text-based), and APK build command (`flutter build apk --release`). Commit message: `chore: final cleanup — docs, formatting, analysis fixes, README` | | |

## 3. Alternatives

- **ALT-001**: **Riverpod** instead of `ChangeNotifier + provider` — Riverpod offers compile-time safety, auto-dispose, and better testability. Not chosen because the Flutter Architecture Recommendations in `.copilot/dart_and_flutter_instructions.md` recommend `ChangeNotifier` + `provider`, and this keeps the stack closer to Flutter SDK defaults.
- **ALT-002**: **Isar** instead of Drift for local database — Isar is NoSQL and faster for simple queries. Not chosen because Drift's SQL-based schema maps cleanly to Supabase PostgreSQL, making sync logic simpler (PRD §4 open question resolved in favor of Drift).
- **ALT-003**: **Firebase** instead of Supabase for cloud backend — Firebase offers richer Flutter SDK. Not chosen because Supabase provides self-hostable PostgreSQL, better aligns with privacy goals, and was specified in the PRD.
- **ALT-004**: **BLoC** pattern instead of MVVM — BLoC is popular in Flutter ecosystem. Not chosen because MVVM with `ChangeNotifier` is recommended by the Flutter team's architecture guide and is simpler for a solo-developer project.
- **ALT-005**: **Background SMS via ContentObserver** instead of `telephony` package — ContentObserver provides lower-level SMS monitoring. Not chosen because `telephony` package abstracts this with a cleaner API and handles Android permission lifecycle.

## 4. Dependencies

- **DEP-001**: `drift: ^2.x` + `sqlite3_flutter_libs` + `drift_dev` (dev) — SQLite ORM for local database
- **DEP-002**: `supabase_flutter: ^2.x` — Supabase client for auth and cloud sync
- **DEP-003**: `enough_mail: ^2.x` — IMAP client for Gmail connection
- **DEP-004**: `html: ^0.15.x` — HTML parser for NayaPay email Types 3 & 4
- **DEP-005**: `flutter_secure_storage: ^9.x` — Encrypted credential storage
- **DEP-006**: `telephony: ^0.2.x` — SMS inbox reading and real-time listening
- **DEP-007**: `fl_chart: ^0.68.x` — Bar and donut charts for dashboard
- **DEP-008**: `go_router: ^14.x` — Declarative navigation and routing
- **DEP-009**: `provider: ^6.x` — Dependency injection and widget rebuilds
- **DEP-010**: `workmanager: ^0.5.x` — Background periodic task scheduling
- **DEP-011**: `permission_handler: ^11.x` — Runtime Android permission requests
- **DEP-012**: `intl: ^0.19.x` — Date formatting and number formatting (PKR)
- **DEP-013**: `freezed: ^2.x` + `freezed_annotation` + `json_serializable` + `json_annotation` — Immutable model code generation
- **DEP-014**: `path_provider: ^2.x` + `path` — File system paths for database location
- **DEP-015**: `build_runner` (dev) — Code generation runner for Drift and freezed
- **DEP-016**: `mockito` (dev) — Mock generation for unit tests
- **DEP-017**: `shared_preferences: ^2.x` — Lightweight key-value storage for onboarding flag

## 5. Files

- **FILE-001**: `lib/main.dart` — App entry point, `MultiProvider` DI setup, `WidgetsFlutterBinding` initialization
- **FILE-002**: `lib/app.dart` — `MaterialApp.router` with `GoRouter` and `AppTheme`
- **FILE-003**: `lib/routing/app_router.dart` — All route definitions, `StatefulShellRoute` for bottom nav, conditional onboarding redirect
- **FILE-004**: `lib/data/database/app_database.dart` — Drift `AppDatabase` class with all tables and DAOs
- **FILE-005**: `lib/data/database/tables/transactions_table.dart` — Drift table matching PRD §4.1 schema
- **FILE-006**: `lib/data/database/tables/categories_table.dart` — Drift table matching PRD §4.2 schema
- **FILE-007**: `lib/data/database/tables/rules_table.dart` — Drift table matching PRD §4.3 schema
- **FILE-008**: `lib/data/database/tables/sync_log_table.dart` — Drift table matching PRD §4.4 schema
- **FILE-009**: `lib/data/database/daos/transactions_dao.dart` — CRUD + queries for transactions
- **FILE-010**: `lib/data/database/daos/categories_dao.dart` — CRUD for categories
- **FILE-011**: `lib/data/database/daos/rules_dao.dart` — CRUD for rules
- **FILE-012**: `lib/data/database/daos/sync_log_dao.dart` — Sync log queries
- **FILE-013**: `lib/data/models/transaction_model.dart` — Freezed immutable transaction model
- **FILE-014**: `lib/data/models/category_model.dart` — Freezed immutable category model
- **FILE-015**: `lib/data/models/rule_model.dart` — Freezed immutable rule model
- **FILE-016**: `lib/data/models/sync_log_model.dart` — Freezed immutable sync log model
- **FILE-017**: `lib/data/models/sync_result.dart` — Freezed sync result model
- **FILE-018**: `lib/data/repositories/transaction_repository.dart` — Abstract interface
- **FILE-019**: `lib/data/repositories/drift_transaction_repository.dart` — Drift-backed implementation
- **FILE-020**: `lib/data/repositories/category_repository.dart` — Abstract interface
- **FILE-021**: `lib/data/repositories/drift_category_repository.dart` — Drift-backed implementation
- **FILE-022**: `lib/data/repositories/rule_repository.dart` — Abstract interface
- **FILE-023**: `lib/data/repositories/drift_rule_repository.dart` — Drift-backed implementation
- **FILE-024**: `lib/data/repositories/sms_import_repository.dart` — Abstract + impl for SMS ingestion
- **FILE-025**: `lib/data/repositories/email_import_repository.dart` — Abstract + impl for email ingestion
- **FILE-026**: `lib/data/repositories/sync_repository.dart` — Abstract + impl for Supabase sync
- **FILE-027**: `lib/data/services/hbl_sms_service.dart` — 3-pattern HBL SMS parser
- **FILE-028**: `lib/data/services/nayapay_email_service.dart` — 4-type NayaPay email parser
- **FILE-029**: `lib/data/services/imap_service.dart` — IMAP connection via enough_mail
- **FILE-030**: `lib/data/services/secure_storage_service.dart` — Encrypted credential storage
- **FILE-031**: `lib/data/services/sms_permission_service.dart` — SMS permission handling
- **FILE-032**: `lib/data/services/sms_inbox_service.dart` — SMS inbox reader + listener
- **FILE-033**: `lib/data/services/supabase_auth_service.dart` — Supabase authentication
- **FILE-034**: `lib/data/services/supabase_sync_service.dart` — Bidirectional sync logic
- **FILE-035**: `lib/data/services/background_sync_service.dart` — Workmanager task registration
- **FILE-036**: `lib/data/services/auto_categorisation_service.dart` — Keyword rule matching
- **FILE-037**: `lib/ui/core/theme.dart` — Material 3 theme with accessibility colors
- **FILE-038**: `lib/ui/core/utils/currency_formatter.dart` — PKR formatting utility
- **FILE-039**: `lib/ui/core/widgets/transaction_card.dart` — Transaction list item widget
- **FILE-040**: `lib/ui/core/widgets/source_badge.dart` — Source chip widget
- **FILE-041**: `lib/ui/core/widgets/category_chip.dart` — Category chip widget
- **FILE-042**: `lib/ui/core/widgets/period_selector.dart` — Period preset selector widget
- **FILE-043**: `lib/ui/core/widgets/setup_banner.dart` — Persistent setup prompt banner
- **FILE-044**: `lib/ui/dashboard/dashboard_screen.dart` — Dashboard view
- **FILE-045**: `lib/ui/dashboard/dashboard_view_model.dart` — Dashboard logic
- **FILE-046**: `lib/ui/dashboard/widgets/summary_cards.dart` — 4 summary card widgets
- **FILE-047**: `lib/ui/dashboard/widgets/spend_bar_chart.dart` — Daily spend bar chart
- **FILE-048**: `lib/ui/dashboard/widgets/category_donut_chart.dart` — Category donut chart
- **FILE-049**: `lib/ui/transactions/transactions_screen.dart` — Transaction list view
- **FILE-050**: `lib/ui/transactions/transactions_view_model.dart` — Transaction list logic
- **FILE-051**: `lib/ui/transactions/transaction_detail_screen.dart` — Detail bottom sheet
- **FILE-052**: `lib/ui/transactions/transaction_detail_view_model.dart` — Detail logic
- **FILE-053**: `lib/ui/add_transaction/add_transaction_screen.dart` — Manual entry form
- **FILE-054**: `lib/ui/add_transaction/add_transaction_view_model.dart` — Manual entry logic
- **FILE-055**: `lib/ui/settings/settings_screen.dart` — Settings view
- **FILE-056**: `lib/ui/settings/settings_view_model.dart` — Settings logic
- **FILE-057**: `lib/ui/settings/email_setup/email_setup_screen.dart` — Email setup view
- **FILE-058**: `lib/ui/settings/email_setup/email_setup_view_model.dart` — Email setup logic
- **FILE-059**: `lib/ui/settings/categories/categories_screen.dart` — Category management
- **FILE-060**: `lib/ui/settings/categories/categories_view_model.dart` — Category logic
- **FILE-061**: `lib/ui/settings/rules/rules_screen.dart` — Auto-rules management
- **FILE-062**: `lib/ui/settings/rules/rules_view_model.dart` — Auto-rules logic
- **FILE-063**: `lib/ui/settings/supabase_auth_screen.dart` — Supabase sign-up/sign-in
- **FILE-064**: `lib/ui/onboarding/onboarding_screen.dart` — 5-step onboarding wizard
- **FILE-065**: `lib/ui/onboarding/onboarding_view_model.dart` — Onboarding logic
- **FILE-066**: `supabase/README.md` — SQL migration scripts and RLS policies
- **FILE-067**: `README.md` — Project documentation

## 6. Testing

- **TEST-001**: Unit tests for `HblSmsService` — all 3 SMS patterns, malformed input, edge cases (TASK-015)
- **TEST-002**: Unit tests for `NayaPayEmailService` — all 4 email types using real `.eml` fixtures, subject-line fast path, HTML fallback (TASK-025)
- **TEST-003**: Unit tests for `SmsImportRepository` — dedup, auto-categorisation, empty inbox (TASK-019)
- **TEST-004**: Unit tests for `EmailImportRepository` — dedup, credential missing, connection failure, auto-categorisation (TASK-027)
- **TEST-005**: Unit tests for `AutoCategorisationService` — keyword matching, case insensitivity, no match (TASK-044)
- **TEST-006**: Unit tests for `CategoriesViewModel` — CRUD, default deletion prevented, reassignment (TASK-044)
- **TEST-007**: Unit tests for `RulesViewModel` — CRUD, bulk application (TASK-044)
- **TEST-008**: Widget tests for `DashboardScreen` — summary cards, charts, period selector, empty state (TASK-037)
- **TEST-009**: Unit + widget tests for manual transaction entry — validation, save, navigation (TASK-047)
- **TEST-010**: Unit tests for `TransactionsViewModel` — pagination, filters, search (TASK-054)
- **TEST-011**: Unit tests for `TransactionDetailViewModel` — load, edit, delete (TASK-054)
- **TEST-012**: Unit tests for `SupabaseSyncService` — upload, download, conflict resolution (TASK-063)
- **TEST-013**: Unit tests for `SyncRepository` — unsynced detection, last sync time (TASK-063)
- **TEST-014**: Unit tests for `SettingsViewModel` — sync status, manual sync (TASK-063)
- **TEST-015**: Unit + widget tests for onboarding flow — step progression, permissions, import count (TASK-069)
- **TEST-016**: End-to-end integration test — full user flow from onboarding through CRUD and settings (TASK-075)

## 7. Risks & Assumptions

- **RISK-001**: `telephony` package may not support all Android OEM SMS implementations (e.g., Xiaomi, Samsung custom SMS apps). Mitigation: test on multiple devices; if `telephony` fails, evaluate `sms_advanced` as drop-in replacement.
- **RISK-002**: HBL may change SMS formats without notice, breaking regex patterns. Mitigation: log unmatched SMS from HBL sender to a debug screen; regex patterns are isolated in `HblSmsService` for easy updates.
- **RISK-003**: NayaPay email HTML structure may change, breaking HTML parsers. Mitigation: subject-line parsing provides a fast path that captures amount and beneficiary even if body parsing fails; HTML parser falls back gracefully.
- **RISK-004**: Gmail App Password setup may confuse non-technical users. Mitigation: step-by-step in-app guide with screenshots in onboarding.
- **RISK-005**: `workmanager` background tasks may be killed by Android battery optimization (Doze mode, OEM-specific restrictions). Mitigation: document in README how to exempt app from battery optimization; sync also runs on app launch and manual trigger.
- **RISK-006**: Supabase free tier has rate limits and storage caps. Mitigation: sync is batched and periodic (30 min); single-user app generates low volume.
- **RISK-007**: Drift code generation (`build_runner`) may have long build times with many models. Mitigation: minimize model count (5 models total); use `--delete-conflicting-outputs` flag.
- **ASSUMPTION-001**: User has a Gmail account with 2-Step Verification enabled (required for App Passwords).
- **ASSUMPTION-002**: HBL SMS sender ID is consistent and filterable (contains "HBL" in sender name/number).
- **ASSUMPTION-003**: NayaPay emails always come from `service@nayapay.com` with consistent subject-line emoji patterns.
- **ASSUMPTION-004**: Device has internet connectivity for initial email sync and Supabase sync (all other features work offline).
- **ASSUMPTION-005**: PKR-only is sufficient for v1 — foreign currency transactions from NayaPay card purchases are tracked at their total PKR converted amount (including fees).
- **ASSUMPTION-006**: Background sync interval of 30 minutes provides acceptable freshness without excessive battery drain.

## 8. Related Specifications / Further Reading

- [PRD.md](../PRD.md) — Full Product Requirements Document (v1.1)
- [.copilot/dart_and_flutter_instructions.md](../.copilot/dart_and_flutter_instructions.md) — Dart/Flutter coding standards and architecture guidelines
- [HBL_SMS/messages.txt](../HBL_SMS/messages.txt) — Real HBL SMS samples (3 patterns)
- [nayapay_emails/](../nayapay_emails/) — Real NayaPay email samples (4 types)
- [Drift documentation](https://drift.simonbinder.eu/) — SQLite ORM for Flutter
- [Supabase Flutter SDK](https://supabase.com/docs/reference/dart/introduction) — Cloud backend
- [enough_mail package](https://pub.dev/packages/enough_mail) — IMAP client for Dart
- [fl_chart package](https://pub.dev/packages/fl_chart) — Flutter charting library
- [Flutter Architecture Recommendations](https://docs.flutter.dev/app-architecture/recommendations) — Official architecture guidance