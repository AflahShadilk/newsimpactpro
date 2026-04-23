# 🚀 NewsImpact Pro — Antigravity Production Spec

> **Version:** 1.0.0 — Production Ready  
> **Stack:** Flutter · Firebase · GetX  
> **Status:** 🟢 Build Ready

---

## 📋 Table of Contents

1. [Product Summary](#1-product-summary)
2. [System Architecture](#2-system-architecture)
3. [Tech Stack](#3-tech-stack)
4. [Authentication & User Data](#4-authentication--user-data)
5. [Database Structure](#5-database-structure)
6. [Notification System](#6-notification-system)
7. [Message Content & Structure](#7-message-content--structure)
8. [Core Logic](#8-core-logic)
9. [Analysis Engine](#9-analysis-engine)
10. [UI Design & Screens](#10-ui-design--screens)
11. [Flutter Project Structure](#11-flutter-project-structure)
12. [Widget Catalogue](#12-widget-catalogue)
13. [Controllers (GetX)](#13-controllers-getx)
14. [Services Layer](#14-services-layer)
15. [Coding Standards](#15-coding-standards)
16. [Security Rules](#16-security-rules)
17. [Performance Guidelines](#17-performance-guidelines)
18. [Git Workflow](#18-git-workflow)
19. [Dependencies](#19-dependencies)
20. [Testing Strategy](#20-testing-strategy)
21. [Play Store Release Checklist](#21-play-store-release-checklist)
22. [Critical Rules](#22-critical-rules)

---

## 1. Product Summary

**NewsImpact Pro** is a production-grade forex trading assistant mobile app that:

- 📡 Tracks **High** and **Medium** impact economic news events
- ⏰ Sends **pre-news alerts** (default: 15 min before) via FCM push notifications
- 📊 Performs **historical impact analysis** (last 5–10 events per currency/event type)
- 🧠 Generates **probability-based directional bias** (bullish / bearish / neutral)
- 🎯 Provides **trade guidance** aligned with price action and volatility patterns
- 🔐 Stores **per-user preferences** securely with Firebase Auth + Firestore rules

---

## 2. System Architecture

```
[Economic Calendar API]
        ↓
   [Cloud Function: Fetcher]          ← runs every 5 min
        ↓
   [Cloud Function: Processor]        ← filters high/medium, deduplicates
        ↓
   [Firestore: news_events]           ← live upcoming events
        ↓
   [Cloud Function: Analysis Engine]  ← reads news_history, computes bias
        ↓
   [Cloud Function: Scheduler]        ← checks alert_time vs now
        ↓
   [Firebase Cloud Messaging (FCM)]   ← pushes to user device tokens
        ↓
      [Flutter App]                   ← renders UI, stores user prefs
```

---

## 3. Tech Stack

### Frontend
| Layer | Technology |
|---|---|
| Framework | Flutter (latest stable) |
| State / Routing | GetX |
| UI Styling | Custom theme + Material 3 |
| Push Handling | firebase_messaging |

### Backend
| Layer | Technology |
|---|---|
| Database | Firebase Firestore |
| Functions | Firebase Cloud Functions (Node.js) |
| Notifications | Firebase Cloud Messaging (FCM) |
| Auth | Firebase Authentication (Email/Google) |

### DevOps
| Tool | Use |
|---|---|
| Git | Version control (branch strategy below) |
| GitHub Actions | CI/CD (lint + test on PR) |
| Firebase Crashlytics | Production crash monitoring |

---

## 4. Authentication & User Data

### 4.1 Auth Flow

```
App Launch
    ↓
Check FirebaseAuth.currentUser
    ├── Exists → load user doc from Firestore → go to Home
    └── Null  → show Login Screen
                  ├── Email/Password → createUser or signIn
                  └── Google Sign-In → GoogleAuthProvider
                                ↓
                        Write user doc to Firestore (first time only)
                                ↓
                           Go to Home
```

### 4.2 User Document — Firestore `users/{uid}`

```json
{
  "uid": "firebase_auth_uid",
  "email": "user@example.com",
  "display_name": "Trader Name",
  "photo_url": "https://...",
  "fcm_token": "device_fcm_token_string",
  "currencies": ["USD", "EUR", "GBP"],
  "impact": ["high", "medium"],
  "alert_time": 15,
  "focus_mode": true,
  "timezone": "America/New_York",
  "notifications_enabled": true,
  "created_at": "timestamp",
  "last_active": "timestamp"
}
```

### 4.3 Field Definitions

| Field | Type | Description |
|---|---|---|
| `uid` | String | Firebase Auth UID (document ID) |
| `email` | String | Login email |
| `display_name` | String | Display name in UI |
| `photo_url` | String | Profile avatar URL |
| `fcm_token` | String | Device token for push delivery — updated on each login |
| `currencies` | String[] | Currencies the user tracks (e.g. USD, EUR) |
| `impact` | String[] | Impact levels to alert on: `["high"]` or `["high","medium"]` |
| `alert_time` | Int | Minutes before news event to send alert (5, 10, 15, 30) |
| `focus_mode` | Bool | Hides medium-impact events from home feed |
| `timezone` | String | IANA timezone string — used for correct alert scheduling |
| `notifications_enabled` | Bool | Global toggle for all push notifications |
| `created_at` | Timestamp | Account creation time |
| `last_active` | Timestamp | Updated on each app open |

### 4.4 FCM Token Management

```dart
// Refresh FCM token on login and update Firestore
final token = await FirebaseMessaging.instance.getToken();
await FirebaseFirestore.instance
    .collection('users')
    .doc(uid)
    .update({'fcm_token': token, 'last_active': FieldValue.serverTimestamp()});

// Listen for token refresh
FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
  // Update Firestore with new token
});
```

---

## 5. Database Structure

### 5.1 `news_events` — Live Upcoming Events

```json
{
  "id": "auto_generated",
  "event_name": "CPI m/m",
  "currency": "USD",
  "impact": "high",
  "time": "2025-04-22T13:30:00Z",
  "forecast": 0.3,
  "previous": 0.2,
  "actual": null,
  "status": "upcoming",
  "alert_sent": false,
  "created_at": "timestamp"
}
```

**`status` values:** `upcoming` → `released` → `archived`

### 5.2 `news_history` — Post-Release Records

```json
{
  "id": "auto_generated",
  "event_name": "CPI m/m",
  "currency": "USD",
  "impact": "high",
  "date": "timestamp",
  "forecast": 0.3,
  "actual": 0.5,
  "deviation": 0.2,
  "price_before": 2300.00,
  "price_after_15m": 2320.00,
  "price_after_1h": 2350.00,
  "direction": "bullish",
  "volatility": 120,
  "pips_moved_15m": 20,
  "pips_moved_1h": 50,
  "created_at": "timestamp"
}
```

### 5.3 `users` — User Preferences (see Section 4.2)

### 5.4 `notifications_log` — Sent Notification Record

```json
{
  "id": "auto_generated",
  "uid": "user_uid",
  "event_id": "news_event_id",
  "type": "pre_news",
  "title": "USD CPI in 15 min",
  "body": "Bullish bias (75%) — Spike + continuation expected",
  "sent_at": "timestamp",
  "delivered": true
}
```

---

## 6. Notification System

### 6.1 Pre-News Alert

**Trigger:** `news_time - now == user.alert_time`

**FCM Payload:**
```json
{
  "to": "user_fcm_token",
  "notification": {
    "title": "🔔 USD CPI in 15 min",
    "body": "Bullish bias (75%) — Spike + continuation expected. Prev: 0.2 | Forecast: 0.3"
  },
  "data": {
    "type": "pre_news",
    "event_id": "news_event_id",
    "currency": "USD",
    "event_name": "CPI m/m",
    "bias": "bullish",
    "confidence": 75,
    "screen": "detail"
  },
  "android": {
    "priority": "high",
    "notification": { "channel_id": "news_alerts" }
  },
  "apns": {
    "payload": { "aps": { "sound": "default", "badge": 1 } }
  }
}
```

### 6.2 Post-News Alert

**Trigger:** When `actual` value is written to Firestore after release

**FCM Payload:**
```json
{
  "to": "user_fcm_token",
  "notification": {
    "title": "📊 USD CPI Released",
    "body": "Actual: 0.5 vs Forecast: 0.3 — Bullish. 120 pip spike. Wait for retest."
  },
  "data": {
    "type": "post_news",
    "event_id": "news_event_id",
    "actual": 0.5,
    "forecast": 0.3,
    "direction": "bullish",
    "volatility": 120,
    "guidance": "Wait for spike + retest before entering",
    "screen": "detail"
  }
}
```

---

## 7. Message Content & Structure

### 7.1 What Every Message Must Include

| Field | Pre-News | Post-News |
|---|---|---|
| Currency + Event Name | ✅ | ✅ |
| Time until / Released | ✅ | ✅ |
| Forecast value | ✅ | ✅ |
| Previous value | ✅ | — |
| Actual value | — | ✅ |
| Bias (bullish/bearish/neutral) | ✅ | ✅ |
| Confidence % | ✅ | — |
| Historical note | ✅ | — |
| Volatility (pips) | — | ✅ |
| Trade guidance | — | ✅ |

### 7.2 Pre-News Message Templates

```
Title: 🔔 {CURRENCY} {EVENT_NAME} in {ALERT_TIME} min
Body:  {BIAS} bias ({CONFIDENCE}%) — {NOTE}
       Prev: {PREVIOUS} | Forecast: {FORECAST}
```

**Examples:**
```
🔔 USD CPI m/m in 15 min
Bullish bias (75%) — Spike + continuation expected
Prev: 0.2 | Forecast: 0.3
```
```
🔔 EUR GDP q/q in 10 min
Neutral bias (50%) — Mixed signals. Trade with caution.
Prev: 0.1 | Forecast: 0.1
```

### 7.3 Post-News Message Templates

```
Title: 📊 {CURRENCY} {EVENT_NAME} Released
Body:  Actual: {ACTUAL} vs Forecast: {FORECAST} — {DIRECTION}
       {VOLATILITY} pip spike. {GUIDANCE}
```

**Examples:**
```
📊 USD CPI m/m Released
Actual: 0.5 vs Forecast: 0.3 — Bullish 🟢
120 pip spike. Wait for retest before entering long.
```
```
📊 GBP PMI Released
Actual: 48.2 vs Forecast: 50.1 — Bearish 🔴
80 pip spike. Avoid early entry. Volatility still high.
```

### 7.4 Trade Guidance Messages (Map)

```dart
// Map actual vs forecast outcome to guidance string
String getGuidance(String direction, int volatility) {
  if (direction == 'bullish' && volatility > 100)
    return 'Wait for spike + retest before entering long.';
  if (direction == 'bullish' && volatility <= 100)
    return 'Steady bullish move. Look for continuation on retest.';
  if (direction == 'bearish' && volatility > 100)
    return 'Volatile spike down. Wait for stabilization before shorting.';
  if (direction == 'bearish' && volatility <= 100)
    return 'Steady bearish move. Look for short on lower high.';
  return 'Neutral outcome. Avoid trading until clear direction forms.';
}
```

---

## 8. Core Logic

### 8.1 Fetch Cycle (Cloud Function)

```
Schedule: every 5 minutes (pub/sub)

1. Call economic calendar API
2. Filter: impact == "high" OR impact == "medium"
3. Check Firestore for existing event (deduplicate by event_name + time)
4. Write new events to news_events collection
5. Log fetch timestamp
```

### 8.2 Alert Scheduler (Cloud Function)

```
Schedule: every 1 minute (pub/sub)

1. Query news_events where status == "upcoming" AND alert_sent == false
2. For each event:
   a. Fetch all users where event.currency ∈ user.currencies
      AND event.impact ∈ user.impact
      AND notifications_enabled == true
   b. Check: event.time - now ≈ user.alert_time (±1 min tolerance)
   c. Build FCM payload with analysis data
   d. Send via FCM to user.fcm_token
   e. Mark event.alert_sent = true
   f. Write to notifications_log
```

### 8.3 Post-News Processor (Cloud Function — Firestore trigger)

```
Trigger: onUpdate of news_events/{id} where actual != null

1. Set status = "released"
2. Read price data (external price API or stored snapshot)
3. Compute direction: actual > forecast → bullish, actual < forecast → bearish
4. Compute pips_moved_15m, pips_moved_1h
5. Write record to news_history
6. Run analysis engine on updated history
7. Send post-news FCM notification to relevant users
```

---

## 9. Analysis Engine

### 9.1 Historical Analysis Query

```dart
// Fetch last 5–10 events for the same event_name + currency
final history = await FirebaseFirestore.instance
    .collection('news_history')
    .where('event_name', isEqualTo: eventName)
    .where('currency', isEqualTo: currency)
    .orderBy('date', descending: true)
    .limit(10)
    .get();
```

### 9.2 Prediction Rules

```dart
String getPrediction(double actual, double forecast) {
  if (actual > forecast) return 'bullish';
  if (actual < forecast) return 'bearish';
  return 'neutral';
}
```

### 9.3 Bias Calculation

```dart
// Count directional outcomes from history
int bullishCount = history.where((e) => e.direction == 'bullish').length;
int bearishCount = history.where((e) => e.direction == 'bearish').length;

String bias = bullishCount > bearishCount ? 'bullish' : 'bearish';
int confidence = ((max(bullishCount, bearishCount) / history.length) * 100).round();
double avgVolatility = history.map((e) => e.volatility).reduce((a, b) => a + b) / history.length;
```

### 9.4 Analysis Output

```json
{
  "bias": "bullish",
  "confidence": 75,
  "avg_volatility": 98.5,
  "bullish_count": 6,
  "bearish_count": 2,
  "sample_size": 8,
  "note": "Spike + continuation expected based on 6/8 bullish outcomes"
}
```

---

## 10. UI Design & Screens

### 10.1 Home Screen

```
┌─────────────────────────────────┐
│  NewsImpact Pro        [⚙ icon] │  ← Top bar
├─────────────────────────────────┤
│  [USD] [EUR] [GBP] [All]        │  ← _filterChip row
│  [High] [Medium]                │
├─────────────────────────────────┤
│  ┌───────────────────────────┐  │
│  │ 🔴 HIGH  USD CPI m/m      │  │  ← _newsCard
│  │ 13:30 UTC | Forecast: 0.3 │  │
│  │ ⏰ Alert in 14 min         │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │ 🟡 MED  EUR GDP q/q       │  │  ← _newsCard
│  │ 09:00 UTC | Forecast: 0.1 │  │
│  └───────────────────────────┘  │
└─────────────────────────────────┘
```

**Color coding:**
- 🔴 High Impact — `Colors.red`
- 🟡 Medium Impact — `Colors.orange`
- ⚪ Released — `Colors.grey`

### 10.2 Detail Screen

```
┌─────────────────────────────────┐
│  ← USD CPI m/m          🔴 HIGH │
├─────────────────────────────────┤
│  📅 Apr 22 · 13:30 UTC          │
│  Forecast: 0.3 | Prev: 0.2      │
│  Actual: 0.5 (Released ✅)      │
├─────────────────────────────────┤
│  📊 HISTORICAL ANALYSIS         │  ← _analysisPanel
│  Last 8 events: 6 bullish 2 bear│
│  Avg Volatility: 98 pips        │
├─────────────────────────────────┤
│  🎯 PREDICTION                  │  ← _predictionPanel
│  Bullish Bias (75% confidence)  │
│  "Spike + continuation expected"│
├─────────────────────────────────┤
│  ⚡ VOLATILITY METER            │  ← _volatilityMeter
│  ████████░░  120 pips           │
├─────────────────────────────────┤
│  🛡 TRADE GUIDANCE              │  ← _guidancePanel
│  Wait for spike + retest before │
│  entering long position.        │
└─────────────────────────────────┘
```

### 10.3 Settings Screen

```
┌─────────────────────────────────┐
│  ← Settings                     │
├─────────────────────────────────┤
│  ALERT TIMING                   │
│  ○ 5 min  ● 15 min  ○ 30 min   │
├─────────────────────────────────┤
│  CURRENCY FILTER                │
│  ☑ USD  ☑ EUR  ☐ GBP  ☐ JPY   │
├─────────────────────────────────┤
│  IMPACT FILTER                  │
│  ☑ High  ☑ Medium               │
├─────────────────────────────────┤
│  FOCUS MODE                     │
│  Show high impact only  [toggle]│
├─────────────────────────────────┤
│  NOTIFICATIONS        [toggle]  │
├─────────────────────────────────┤
│  TIMEZONE                       │
│  America/New_York          [>]  │
└─────────────────────────────────┘
```

---

## 11. Flutter Project Structure

```
lib/
├── core/
│   ├── theme/
│   │   ├── app_theme.dart          # Global MaterialTheme
│   │   └── app_colors.dart         # Color constants
│   ├── constants/
│   │   ├── app_strings.dart        # UI text constants
│   │   └── app_routes.dart         # Named route constants
│   └── utils/
│       ├── date_utils.dart         # Timezone + formatting helpers
│       └── impact_utils.dart       # Impact → color/label helpers
│
├── data/
│   ├── models/
│   │   ├── news_event.dart         # NewsEvent model
│   │   ├── news_history.dart       # NewsHistory model
│   │   ├── user_model.dart         # UserModel
│   │   ├── analysis_result.dart    # AnalysisResult model
│   │   └── notification_log.dart   # NotificationLog model
│   └── repositories/
│       ├── news_repository.dart    # Firestore queries for news
│       ├── history_repository.dart # Firestore queries for history
│       └── user_repository.dart    # Firestore queries for user doc
│
├── modules/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── auth_controller.dart
│   ├── home/
│   │   ├── home_screen.dart
│   │   └── home_controller.dart
│   ├── detail/
│   │   ├── detail_screen.dart
│   │   └── detail_controller.dart
│   └── settings/
│       ├── settings_screen.dart
│       └── settings_controller.dart
│
├── controllers/
│   ├── news_controller.dart        # Fetch + store news
│   ├── analysis_controller.dart    # Bias + confidence logic
│   ├── notification_controller.dart# FCM token + message handling
│   └── settings_controller.dart    # User preference state
│
├── services/
│   ├── firebase_service.dart       # Firestore init + helpers
│   ├── fcm_service.dart            # FCM setup + token management
│   ├── auth_service.dart           # Firebase Auth operations
│   └── news_api_service.dart       # External calendar API fetch
│
├── widgets/
│   ├── _news_card.dart
│   ├── _impact_badge.dart
│   ├── _analysis_panel.dart
│   ├── _prediction_panel.dart
│   ├── _guidance_panel.dart
│   ├── _volatility_meter.dart
│   └── _filter_chip.dart
│
├── routes/
│   └── app_pages.dart              # GetX route definitions
│
└── main.dart                       # App entry point + Firebase init
```

---

## 12. Widget Catalogue

> **Rule:** Private widgets start with `_` (underscore). No `_build` prefix. Name must describe content.

| Widget | File | Description |
|---|---|---|
| `_newsCard` | `_news_card.dart` | Scrollable card showing event name, currency, time, impact badge, alert countdown |
| `_impactBadge` | `_impact_badge.dart` | Colored dot/chip — RED (high), ORANGE (medium), GREY (released) |
| `_analysisPanel` | `_analysis_panel.dart` | Historical breakdown: bullish/bearish count, sample size, avg volatility |
| `_predictionPanel` | `_prediction_panel.dart` | Bias label, confidence %, explanatory note |
| `_guidancePanel` | `_guidance_panel.dart` | Trade guidance text based on direction + volatility |
| `_volatilityMeter` | `_volatility_meter.dart` | Linear progress bar showing pip volatility with label |
| `_filterChip` | `_filter_chip.dart` | Toggleable chip for currency/impact filtering on home screen |

---

## 13. Controllers (GetX)

### NewsController
```dart
// Responsibilities: fetch upcoming news from Firestore, apply user filters, expose list
class NewsController extends GetxController {
  final RxList<NewsEvent> events = <NewsEvent>[].obs;
  final RxBool isLoading = false.obs;

  // Fetch filtered news from Firestore
  Future<void> fetchNews() async { ... }

  // Apply currency + impact filter from SettingsController
  List<NewsEvent> get filteredEvents { ... }
}
```

### AnalysisController
```dart
// Responsibilities: compute bias, confidence, avg volatility from history
class AnalysisController extends GetxController {
  // Fetch history and run bias calculation
  Future<AnalysisResult> analyze(String eventName, String currency) async { ... }

  // Map direction outcome to guidance string
  String getGuidance(String direction, int volatility) { ... }
}
```

### NotificationController
```dart
// Responsibilities: init FCM, handle foreground messages, deep-link to detail
class NotificationController extends GetxController {
  // Setup FCM listeners and permission request
  Future<void> init() async { ... }

  // Handle incoming FCM message and route to correct screen
  void _handleMessage(RemoteMessage message) { ... }

  // Refresh and save FCM token to Firestore
  Future<void> refreshToken(String uid) async { ... }
}
```

### SettingsController
```dart
// Responsibilities: load, update, persist user preferences
class SettingsController extends GetxController {
  final Rx<UserModel> user = UserModel.empty().obs;

  // Load user document from Firestore
  Future<void> loadUser(String uid) async { ... }

  // Save updated preferences to Firestore
  Future<void> savePreferences() async { ... }
}
```

---

## 14. Services Layer

| Service | Responsibility |
|---|---|
| `AuthService` | signIn, signUp, signOut, currentUser, Google OAuth |
| `FirebaseService` | Firestore instance, read/write helpers, batch ops |
| `FCMService` | getToken, onTokenRefresh, requestPermissions, send payload |
| `NewsApiService` | HTTP call to external economic calendar API, parse JSON |

---

## 15. Coding Standards

### Single Responsibility
- One class = one responsibility
- No business logic inside widget files
- Services handle Firebase / HTTP
- Controllers handle state and computed values

### Comment Style (one-line only)
```dart
// Fetch news from Firestore
// Calculate bullish count
// Send pre-news notification
// Update FCM token on refresh
```

### Widget Naming
```dart
// ✅ CORRECT
class _newsCard extends StatelessWidget { ... }
class _impactBadge extends StatelessWidget { ... }

// ❌ WRONG
class _buildCard extends StatelessWidget { ... }
Widget _buildNewsList() { ... }
```

### Reactive State (GetX)
```dart
// Use .obs for reactive variables
final RxList<NewsEvent> events = <NewsEvent>[].obs;
final RxBool isLoading = false.obs;

// Use Obx() in UI to rebuild on change
Obx(() => _newsCard(event: controller.events[index]))
```

---

## 16. Security Rules

### Firestore Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Users can only read/write their own document
    match /users/{uid} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }

    // News events: read for all authenticated users, write only by Cloud Functions
    match /news_events/{id} {
      allow read: if request.auth != null;
      allow write: if false; // Cloud Functions only (admin SDK bypasses)
    }

    // History: read for all authenticated users, write by Cloud Functions only
    match /news_history/{id} {
      allow read: if request.auth != null;
      allow write: if false;
    }

    // Notification log: user can only read their own logs
    match /notifications_log/{id} {
      allow read: if request.auth != null && resource.data.uid == request.auth.uid;
      allow write: if false;
    }
  }
}
```

### Input Validation
- Validate all user preference writes on client before Firestore write
- Cloud Functions validate all API data before writing to Firestore
- Prevent duplicate events by checking `event_name + time` composite before insert

---

## 17. Performance Guidelines

| Concern | Strategy |
|---|---|
| News list | Paginate: load 20 events at a time with Firestore `.limit()` |
| History queries | Cache last result per event in memory with `AnalysisController` |
| History load | Lazy load — only fetch when user opens Detail screen |
| Rebuilds | Scope `Obx()` wrappers to smallest possible widget subtree |
| Firestore reads | Use `SnapshotOptions(serverTimestamps: 'estimate')` for offline |
| Images/assets | Precache splash + icon assets in `main.dart` |

---

## 18. Git Workflow

### Branch Structure

```
main          → Production builds (Play Store)
develop       → Integration / staging
feature/*     → New feature development
bugfix/*      → Bug fixes
hotfix/*      → Emergency production fixes
```

### Example Branches
```
feature/news-fetch
feature/analysis-engine
feature/notification-pre-news
feature/ui-home-screen
feature/auth-google-signin
bugfix/timezone-conversion
bugfix/duplicate-events
hotfix/fcm-token-null-crash
```

### Commit Format
```
type(scope): short description
```

| Type | When to Use |
|---|---|
| `feat` | New feature |
| `fix` | Bug fix |
| `refactor` | Code change without new feature or fix |
| `test` | Adding or updating tests |
| `docs` | Documentation changes |
| `chore` | Build config, dependency updates |

**Examples:**
```
feat(news): add firestore fetch logic with 5min schedule
feat(notification): implement pre-news FCM alert with bias
feat(analysis): calculate bullish/bearish bias from history
fix(timezone): correct UTC to local conversion for alert scheduler
refactor(ui): optimize _newsCard to minimize Obx rebuilds
test(analysis): add unit tests for bias calculation logic
```

### Merge Strategy
```
feature/* → develop   (PR, code review required)
develop   → main      (PR, all tests must pass)
hotfix/*  → main      (direct merge with tag)
hotfix/*  → develop   (sync immediately after)
```

---

## 19. Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  get: ^4.6.6                    # State management + routing
  firebase_core: ^3.x.x          # Firebase initialization
  cloud_firestore: ^5.x.x        # Firestore database
  firebase_auth: ^5.x.x          # Authentication
  firebase_messaging: ^15.x.x    # FCM push notifications
  firebase_crashlytics: ^4.x.x   # Crash reporting (production)
  google_sign_in: ^6.x.x         # Google OAuth
  intl: ^0.19.x                  # Date/time formatting
  http: ^1.2.x                   # External API calls
  timezone: ^0.9.x               # IANA timezone support

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.x.x
  mockito: ^5.x.x                # Mock for unit tests
```

---

## 20. Testing Strategy

### Unit Tests
```
test/unit/
├── analysis_controller_test.dart   # Bias calculation, confidence, guidance mapping
├── news_repository_test.dart       # Firestore query logic (mocked)
└── date_utils_test.dart            # Timezone conversion helpers
```

### Widget Tests
```
test/widget/
├── news_card_test.dart             # Renders correctly with high/medium/released states
├── impact_badge_test.dart          # Correct color per impact level
└── volatility_meter_test.dart      # Progress bar renders correct proportion
```

### Manual Tests
- [ ] Pre-news notification fires at correct time per `alert_time`
- [ ] Timezone offset does not shift alert by ±1hr
- [ ] FCM token updates correctly after logout/login
- [ ] Focus mode hides medium events correctly
- [ ] Analysis panel shows correct bias when history is 0, 1, 10 records

---

## 21. Play Store Release Checklist

- [ ] App icon (512x512 PNG, no transparency)
- [ ] Splash screen (light + dark variants)
- [ ] Privacy policy URL live and linked in listing
- [ ] `minSdkVersion 21`, `targetSdkVersion 34`
- [ ] Version name + code set in `pubspec.yaml`
- [ ] `google-services.json` in `android/app/`
- [ ] `GoogleService-Info.plist` in `ios/Runner/`
- [ ] Firebase Crashlytics enabled
- [ ] Release keystore configured in `build.gradle`
- [ ] Obfuscation enabled: `--obfuscate --split-debug-info`
- [ ] App tested on Android 8, 10, 12, 14 physical devices
- [ ] FCM background handling tested on killed-state app

---

## 22. Critical Rules

```
❌ Never promise trade direction — always show bias + probability
✅ Always display confidence % alongside bias
✅ Always handle timezone correctly — store UTC, display local
✅ Ensure notification fires within ±1 min of scheduled time
✅ Validate actual vs forecast before writing to history
✅ Deduplicate news events before writing to Firestore
✅ Never expose FCM tokens or user data in logs
✅ Test analysis engine with 0, 1, and 10 history records
```

---

## ✅ Final Checklist

| Layer | Status |
|---|---|
| Auth flow (Email + Google) | Ready to build |
| User document structure | Defined |
| FCM token management | Defined |
| Database schema (3 collections) | Defined |
| Notification payloads (pre + post) | Defined |
| Message content templates | Defined |
| Analysis engine logic | Defined |
| Flutter folder structure | Defined |
| Widget catalogue | Defined |
| GetX controllers | Defined |
| Firestore security rules | Defined |
| Git workflow | Defined |
| Testing strategy | Defined |
| Play Store checklist | Defined |

---

> 🔥 **Antigravity — Production Ready. Start with `feature/auth-google-signin` → `feature/news-fetch` → `feature/analysis-engine` → `feature/ui-home-screen`**
