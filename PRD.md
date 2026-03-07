# Kangal — Personal Finance App
## Product Requirements Document

**Platform:** Android only · **Stack:** Flutter / Dart · **Storage:** Local-first (SQLite via Drift) + cloud sync (Supabase PostgreSQL)

| Field | Value |
|-------|-------|
| Author | Umer Sani |
| Version | 1.0 (Draft) |
| Date | March 2025 |
| Status | Pre-development |

---

## 1. Overview

Kangal is a local-first, offline-capable personal finance app for Android that automatically tracks spending from Pakistani banks. Users connect their HBL account via SMS parsing and their NayaPay account via email parsing. All data lives on-device in SQLite as the source of truth, with optional cloud backup and sync via Supabase for data safety and multi-device access.

### 1.1 Problem Statement

Pakistani bank apps (HBL, NayaPay) offer no built-in expense tracking or categorisation. Users who want visibility into their spending must either manually log every transaction or resort to spreadsheets. Kangal solves this by automatically ingesting transactions from SMS alerts and email notifications, giving users a clear financial picture with zero manual effort.

### 1.2 Goals

- Automate transaction ingestion from HBL (SMS) and NayaPay (email) with minimal setup.
- Give users a clear, at-a-glance dashboard showing spend, income, and balance.
- Allow flexible manual entry for cash or unsupported bank transactions.
- Support category tagging so users can understand where money goes.
- Keep all data private — local-first with optional cloud backup via Supabase for sync and data safety.
- Enable cross-device sync and cloud backup without sacrificing offline usability.

### 1.3 Non-Goals (v1)

- No iOS support
- No budget limits or goal tracking
- No support for banks other than HBL and NayaPay
- No multi-currency support
- No receipt scanning or OCR

---

## 2. Target User

| Attribute | Description |
|-----------|-------------|
| Name | Umer (primary) |
| Location | Pakistan |
| Banks used | HBL (main), NayaPay (digital wallet) |
| Device | Android smartphone |
| Tech comfort | Medium-high — comfortable with app setup |
| Pain point | No unified view of spending across both banks |
| Goal | Know exactly how much is being spent and on what |

---

## 3. Feature Requirements

### 3.1 HBL Transaction Ingestion (SMS Parser)

HBL sends SMS alerts for debit transactions via Raast and other transfers. The app will read these messages using Android's SMS permission and extract transaction data using regex.

#### 3.1.1 SMS Permission Flow

- On first launch, request `READ_SMS` permission.
- If denied, show a persistent banner explaining why it's needed.
- On permission grant, perform an initial historical SMS scan (last 90 days).
- Background listener monitors new incoming SMS in real time.

#### 3.1.2 Parsing Logic

HBL sends multiple SMS formats. The app must handle **three distinct patterns** observed in real SMS data:

**Pattern A — Debit Card Charge (POS / online):**
```
Your HBL Debit Card has been charged for a Transaction of PKR 1712.19 on 05/03/2026 19:21:32.
```

**Pattern B — ATM Cash Withdrawal:**
```
Your HBL A/C 2456***76703 has been debited with PKR 5,000.00 on 12/02/2026 16:30:19 for ATM Cash Withdrawal.
```

**Pattern C — Raast / IBFT Received (Income):**
```
UMER, PKR 380.00 received from HUZAIFA BIN KHALID A/C via Raast on 10/02/2026 14:10:15, TXN ID SM1014095380DD53. UAN:021111111425.
```

| Field | Pattern A | Pattern B | Pattern C |
|-------|-----------|-----------|----------|
| `amount` | Negative (expense) | Negative (expense) | **Positive (income)** |
| `date` | Embedded `DD/MM/YYYY HH:MM:SS` | Embedded `DD/MM/YYYY HH:MM:SS` | Embedded `DD/MM/YYYY HH:MM:SS` |
| `beneficiary` | N/A (unknown merchant) | `"ATM Cash Withdrawal"` | Sender name (e.g. `HUZAIFA BIN KHALID`) |
| `transaction_id` | None (use hash of body) | None (use hash of body) | `TXN ID` value (e.g. `SM1014095380DD53`) |
| `source` | `"HBL"` | `"HBL"` | `"HBL"` |
| `type` | `"card_charge"` | `"atm_withdrawal"` | `"raast_received"` |
| `subject` | Full SMS body | Full SMS body | Full SMS body |

#### 3.1.3 Deduplication

- Before inserting, check if `transaction_id` already exists in the database.
- Skip duplicates silently. Log to debug output.

---

### 3.2 NayaPay Transaction Ingestion (Email Parser)

NayaPay sends email receipts for every successful transaction. The app connects to the user's Gmail account via IMAP and scans for NayaPay emails.

#### 3.2.1 Email Auth Setup

- Prompt user to enter Gmail address and Gmail App Password (not the main password).
- Show a step-by-step in-app guide to generate a Gmail App Password.
- Store credentials securely using `flutter_secure_storage` (encrypted, backed by Android Keystore).
- Credentials never leave the device — IMAP connection goes from device directly to Gmail.

#### 3.2.2 Parsing Logic

**Sender:** `service@nayapay.com` (Reply-To: `noreply@nayapay.com`)

NayaPay sends **four distinct email types**, identified by the subject line pattern:

**Type 1 — Money Received (Income):**
- Subject: `You got Rs. [AMOUNT] from [NAME] 🎉`
- Amount is **positive** (income)
- `text/plain` contains: `[amount] [name] [txn_id] [date] [sender_tag]`
- Example plaintext: `1,000 Muhammad Haseeb 6946dfc18c69f71921ef7312 20 Dec 2025, 10:41 PM takochi78`

**Type 2 — Sent to NayaPay User (Expense):**
- Subject: `You sent Rs. [AMOUNT] to [NAME] 💸`
- Amount is **negative** (expense)
- `text/plain` contains: `[amount] [name] [txn_id] [date] [sender_tag] [receiver_tag]`
- Example plaintext: `1,450 Muhammad Umer Ghafoor 6999e58a6fc5dc6850e070a0 21 Feb 2026, 10:04 PM umersanii umerghafoor`

**Type 3 — Sent to External Bank via Raast/IBFT (Expense):**
- Subject: `You sent Rs. [AMOUNT] to [NAME] 💸`
- Amount is **negative** (expense)
- `text/plain` may be **empty** — must parse HTML body
- HTML contains: beneficiary name, destination bank (e.g. `easypaisa Bank`), masked account number, date, channel (`Raast`)
- Transaction ID from HTML: e.g. `69a915b83fdee53824a35dbc`

**Type 4 — Online Card Purchase (Expense):**
- Subject: `You spent Rs. [AMOUNT] at [MERCHANT] 💳`
- Amount is **negative** (expense)
- `text/plain` may be **empty** — must parse HTML body
- HTML contains: merchant name + location, transaction type (`Online Transaction`), card info (`Visa ●●●●0268`), merchant category, fees breakdown (FX Settlement, Int. Transaction Fees, SST)
- Transaction ID from HTML: e.g. `337725`

> **Important:** The `text/plain` part is unreliable for Types 3 & 4 (often empty). The parser must fall back to HTML extraction using regex or an HTML parser for these types.

| Field | Type 1 (Received) | Type 2 (Sent P2P) | Type 3 (Sent to Bank) | Type 4 (Card Purchase) |
|-------|-------------------|-------------------|-----------------------|------------------------|
| `amount` | Positive (income) | Negative (expense) | Negative (expense) | Negative (expense) |
| `date` | Email body / header | Email body / header | HTML body | HTML body |
| `beneficiary` | Sender name | Recipient name | Recipient name | Merchant name + location |
| `transaction_id` | Plaintext / HTML | Plaintext / HTML | HTML only | HTML only |
| `source` | `"NayaPay"` | `"NayaPay"` | `"NayaPay"` | `"NayaPay"` |
| `type` | `"received"` | `"sent_p2p"` | `"sent_bank"` | `"card_purchase"` |
| `subject` | Email subject | Email subject | Email subject | Email subject |
| `extra` | — | — | Dest. bank, account | Card number, merchant category, fees |

#### 3.2.3 Sync Behaviour

- On setup completion: scan last 90 days of emails from `service@nayapay.com`.
- Manual refresh button triggers a fresh IMAP scan.
- Optional: background periodic sync every 30 minutes via `workmanager`.
- Deduplication by `transaction_id` before insert.

#### 3.2.4 Subject-Line Parsing Shortcut

All four NayaPay email types encode amount and beneficiary/merchant directly in the subject line:
- `You got Rs. {amount} from {name} 🎉` → income
- `You sent Rs. {amount} to {name} 💸` → expense (P2P or bank)
- `You spent Rs. {amount} at {merchant} 💳` → expense (card)

The subject line can be parsed first as a fast path. The full body is then parsed for `transaction_id`, date/time, and additional details (destination bank, card info, fees).

---

### 3.3 Transaction List & History

A scrollable, filterable list of all transactions — the core screen of the app.

#### 3.3.1 Display

- Each transaction shown as a card: amount, beneficiary, date, source badge (HBL / NayaPay / Cash), category chip.
- Expenses in red, income in green.
- Sorted by date descending by default.
- Infinite scroll / pagination (load 50 at a time).

#### 3.3.2 Filtering & Search

- Filter by source: HBL, NayaPay, Manual/Cash, All.
- Filter by category.
- Filter by date range — presets: Today, This Week, This Month, Custom.
- Full-text search on beneficiary and subject.

#### 3.3.3 Transaction Detail

- Tap a transaction to open a detail bottom sheet.
- Show all fields including raw subject / SMS body.
- Allow editing of category and adding a personal note.
- Option to delete a transaction (with confirmation dialog).

---

### 3.4 Dashboard / Summary

An overview screen showing the user's financial picture for the selected period.

#### 3.4.1 Summary Cards

| Card | Formula |
|------|---------|
| Total Spent | Sum of negative amounts in period |
| Total Income | Sum of positive amounts in period |
| Net Balance | Income − Expenses |
| Transaction Count | Count of transactions in period |

#### 3.4.2 Charts

- **Bar chart** — daily or weekly spend over selected period.
- **Donut chart** — spending breakdown by category.
- Use `fl_chart` package (Flutter-native, no external API).

#### 3.4.3 Period Selector

- Quick-select: This Week / This Month / Last Month / All Time.
- All dashboard data and charts update when period changes.

---

### 3.5 Manual Transaction Entry

Allows users to log cash transactions or transfers from unsupported banks.

#### 3.5.1 Entry Form

| Field | Type | Required |
|-------|------|----------|
| Amount | Number input (positive = income, negative = expense) | Yes |
| Date & Time | Date/time picker (defaults to now) | Yes |
| Beneficiary | Text input | No |
| Category | Dropdown (see §3.6) | No |
| Note | Multi-line text | No |
| Source | Dropdown: Cash / Other | Yes |

- Validation: amount must be non-zero; date must not be in the future.

---

### 3.6 Category Tagging

#### 3.6.1 Default Categories

Provided out of the box, non-deletable:

`Food & Dining` · `Transport` · `Utilities` · `Shopping` · `Health` · `Education` · `Entertainment` · `Salary/Income` · `Transfer` · `Other`

#### 3.6.2 Custom Categories

- Users can add custom categories (name + colour + emoji).
- Users can edit or delete custom categories.
- Deleting a category reassigns its transactions to "Other".

#### 3.6.3 Auto-Categorisation (Rule-Based)

- Users define keyword rules: if beneficiary contains `"Shell"` → assign `Transport`.
- Rules apply automatically on import and manual entry.
- Rules are stored locally and editable from Settings.

---

## 4. Data Model

### 4.1 Transactions

```sql
CREATE TABLE transactions (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    remote_id       TEXT,                   -- Supabase UUID (NULL until synced)
    date            TEXT NOT NULL,          -- ISO 8601: YYYY-MM-DD HH:MM:SS
    amount          REAL NOT NULL,          -- Negative = expense, Positive = income
    source          TEXT NOT NULL,          -- HBL | NayaPay | Cash | Other
    type            TEXT,                   -- card_charge | atm_withdrawal | raast_received | received | sent_p2p | sent_bank | card_purchase | manual
    transaction_id  TEXT UNIQUE,            -- Bank-assigned; NULL for manual entries
    beneficiary     TEXT,
    subject         TEXT,                   -- Raw SMS body or email subject
    category_id     INTEGER REFERENCES categories(id),
    note            TEXT,
    extra           TEXT,                   -- JSON blob for additional fields (dest_bank, card_info, merchant_category, fees)
    synced_at       TIMESTAMP,              -- NULL = not yet synced to Supabase
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 4.2 Categories

```sql
CREATE TABLE categories (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    name        TEXT NOT NULL,
    emoji       TEXT,
    color       TEXT,                       -- Hex string e.g. "#FF5733"
    is_default  INTEGER DEFAULT 0           -- 1 = non-deletable default
);
```

### 4.3 Rules

```sql
CREATE TABLE rules (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    keyword     TEXT NOT NULL,              -- Matched against beneficiary (case-insensitive)
    category_id INTEGER REFERENCES categories(id)
);
```

### 4.4 Sync Metadata

```sql
CREATE TABLE sync_log (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    table_name      TEXT NOT NULL,          -- 'transactions' | 'categories' | 'rules'
    last_synced_at  TIMESTAMP NOT NULL,
    status          TEXT DEFAULT 'success'  -- 'success' | 'partial' | 'failed'
);
```

> **Local ORM:** [Drift](https://drift.simonbinder.eu/) — type-safe SQLite wrapper for Flutter.
> **Remote DB:** [Supabase](https://supabase.com/) — PostgreSQL-backed BaaS with Flutter SDK. Mirrors the local schema.

---

## 4.5 Supabase Sync Architecture

### 4.5.1 Approach: Local-First with Background Sync

- **SQLite (Drift) is always the source of truth.** Reads and writes happen locally first.
- Supabase mirrors the local schema (transactions, categories, rules) in PostgreSQL.
- Sync is **eventual** — triggered manually, on app launch, and via background `workmanager` intervals.

### 4.5.2 Auth

- Supabase email/password sign-up (optional during onboarding, can set up later in Settings).
- Auth token stored securely via `flutter_secure_storage`.
- If the user skips Supabase sign-up, the app works fully offline with no sync.

### 4.5.3 Sync Flow

1. **Upload:** Push local records where `synced_at IS NULL` or `updated_at > synced_at` to Supabase.
2. **Download:** Pull records from Supabase where `updated_at > last_synced_at` (from `sync_log`).
3. **Conflict resolution:** Last-write-wins based on `updated_at` timestamp.
4. On success, set `synced_at = NOW()` on each synced local record and update `sync_log`.

### 4.5.4 Row-Level Security (RLS)

- Each Supabase table includes a `user_id UUID REFERENCES auth.users(id)` column.
- RLS policies enforce that users can only SELECT/INSERT/UPDATE/DELETE their own rows.

### 4.5.5 Sync Status UI

- Settings screen shows last successful sync timestamp.
- Manual "Sync Now" button.
- Badge / indicator if there are un-synced local changes.

---

## 5. Screens & Navigation

| Screen | Route | Description |
|--------|-------|-------------|
| Dashboard | `/` | Summary cards + charts for selected period |
| Transactions | `/transactions` | Paginated list with filters and search |
| Transaction Detail | `/transactions/:id` | Full detail + edit category / note |
| Add Transaction | `/add` | Manual entry form |
| Settings | `/settings` | Email/SMS setup, categories, rules, about |
| Email Setup | `/settings/email` | Gmail credentials wizard |
| Categories | `/settings/categories` | Manage and create categories |
| Rules | `/settings/rules` | Auto-categorisation rules |
| Onboarding | `/onboarding` | First-launch flow (permissions + bank setup) |

Bottom navigation bar with three tabs: **Dashboard**, **Transactions**, **Settings**.  
Routing: `go_router`.

---

## 6. Non-Functional Requirements

| Category | Requirement |
|----------|-------------|
| Performance | App cold start < 2s. Transaction list renders 50 rows in < 500ms. |
| Offline | Local-first: 100% functional with no internet. Email sync and Supabase sync require network; all other features work offline. |
| Sync | Local SQLite is source of truth. Supabase sync is background + manual. Conflict resolution: last-write-wins based on `updated_at`. |
| Security | Gmail credentials stored in `flutter_secure_storage` (AES-256 backed by Android Keystore). Supabase auth via email/password or magic link. No credentials logged or cached in plaintext. |
| Privacy | No analytics, no crash reporting (v1). Remote data transmission limited to IMAP (Gmail) and Supabase (user's own data). |
| Accessibility | Minimum 4.5:1 contrast ratio. Supports system font scaling. |
| Min Android | Android 8.0 (API 26) or higher. |
| APK size | Target < 25 MB. |
| Localisation | English only for v1. |

---

## 7. Technical Stack

| Layer | Package / Tool | Purpose |
|-------|---------------|---------|
| UI framework | Flutter 3.x | Cross-platform UI (Android target) |
| Language | Dart 3.x | |
| Local database | [Drift](https://drift.simonbinder.eu/) | Type-safe SQLite ORM (local-first storage) |
| Remote database | [Supabase](https://supabase.com/) + [supabase_flutter](https://pub.dev/packages/supabase_flutter) | PostgreSQL BaaS for cloud backup & sync |
| Email / IMAP | [enough_mail](https://pub.dev/packages/enough_mail) | IMAP client for NayaPay parsing |
| HTML parsing | [html](https://pub.dev/packages/html) | Parse NayaPay email HTML bodies (Types 3 & 4) |
| Secure storage | [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) | Store Gmail credentials |
| SMS reading | [telephony](https://pub.dev/packages/telephony) or [sms_advanced](https://pub.dev/packages/sms_advanced) | Read and listen to SMS for HBL |
| Charts | [fl_chart](https://pub.dev/packages/fl_chart) | Dashboard bar + donut charts |
| Navigation | [go_router](https://pub.dev/packages/go_router) | Declarative routing |
| State management | [Riverpod](https://riverpod.dev/) | App state, async data |
| Background sync | [workmanager](https://pub.dev/packages/workmanager) | Periodic email + Supabase sync |
| Permissions | [permission_handler](https://pub.dev/packages/permission_handler) | Runtime permission requests |
| Date / time | [intl](https://pub.dev/packages/intl) | Date formatting (PKT timezone) |

---

## 8. Onboarding Flow

First-launch wizard guiding the user through bank setup:

| Step | Screen | Action |
|------|--------|--------|
| 1 | Welcome | Brief intro to Kangal. CTA: Get Started. |
| 2 | HBL SMS Setup | Explain SMS permission. Request `READ_SMS`. If granted, trigger initial 90-day scan. |
| 3 | NayaPay Email Setup | Explain Gmail App Password. Link to guide. Input email + app password. Test IMAP connection. |
| 4 | Cloud Backup (optional) | Explain Supabase sync. Sign up or skip. |
| 5 | Done | Show transaction count imported. Navigate to Dashboard. |

- Each step can be skipped and revisited from Settings.
- Skipping both steps lands the user on an empty dashboard with a setup prompt banner.

---

## 9. Out of Scope (v1)

- iOS support
- Push notifications for new transactions
- Multi-user or family accounts
- Budget limits or savings goals
- Investment / stock tracking
- Additional banks (Meezan, UBL, JazzCash, etc.)
- Dark mode *(quick win for v1.1)*
- CSV / PDF export
- Google Drive export (Supabase replaces this need)

---

## 10. Open Questions

| # | Question | Status |
|---|----------|--------|
| 1 | Does HBL send consistent SMS patterns across all transaction types (ATM, POS, IBFT, Raast)? | **Resolved** — Three distinct patterns confirmed: debit card charge, ATM withdrawal, Raast received. More patterns may exist (POS, IBFT debit) and should be added as discovered. |
| 2 | Should background email sync run while the app is closed? (battery vs. freshness tradeoff) | Open |
| 3 | What is the exact NayaPay email body format for all transfer types (wallet-to-wallet, bank transfer)? | **Resolved** — Four email types documented: received (🎉), sent P2P (💸), sent to bank (💸 + Raast), card purchase (💳). `text/plain` is empty for Types 3 & 4; HTML parsing required. |
| 4 | Is Drift the right ORM or should Isar be evaluated first? | **Resolved** — Drift chosen. SQL-based schema maps cleanly to Supabase PostgreSQL for sync. |
| 5 | Should the app support PKR-only or allow USD entries (relevant for freelancers)? | Open |
| 6 | Supabase Row-Level Security (RLS) policy design — should each user see only their own data? | Open (default: yes) |
| 7 | Should Supabase sync happen on every local write or only on manual/background triggers? | Open |
| 8 | NayaPay card purchase emails show an amount in foreign currency converted to PKR with fees — should the app track the base amount separately? | Open |

---

## 11. Development Milestones

| Milestone | Deliverables | Est. Duration |
|-----------|-------------|---------------|
| M1 — Foundation | Project setup, Drift schema, Supabase project + tables, empty transaction list screen | 1 week |
| M2 — SMS Parser | HBL SMS permission, 3-pattern parsing logic (card charge, ATM, Raast received), import into DB | 1–2 weeks |
| M3 — Email Parser | IMAP integration, NayaPay 4-type parsing (subject + HTML), dedup, manual refresh | 2–3 weeks |
| M4 — Dashboard | Summary cards, fl_chart integration, period selector | 1 week |
| M5 — Categories | Default categories, custom categories, auto-rules | 1 week |
| M6 — Manual Entry | Add transaction form, validation | 3–5 days |
| M7 — Supabase Sync | Auth flow, background + manual sync, conflict resolution, sync status UI | 1–2 weeks |
| M8 — Onboarding | First-launch wizard, permissions flow, optional Supabase account setup | 3–5 days |
| M9 — Polish & QA | UI polish, edge cases, performance testing | 1 week |

**Total estimated timeline: 10–13 weeks solo development.**

---

*Kangal PRD v1.1 — Umer Sani — March 2025 (Updated March 2026: real SMS/email patterns, Supabase sync)*