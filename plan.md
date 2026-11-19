# ParhaiMate — Product & Development Plan

**Document version:** 1.0  
**Date:** 19 November 2026  
**Platform:** Android  
**Framework:** Flutter  
**Architecture:** MVVM (Model–View–ViewModel)  
**State management & dependency injection:** GetX  
**Database:** SQLite using Drift  
**App name:** ParhaiMate  
**Tagline:** Your Personal Study Companion

---

## 1. Product Overview

ParhaiMate is an offline-first Android study productivity app. It helps students organize subjects, plan study tasks, focus with timers, track study sessions, set goals, maintain streaks, and understand their study progress.

### Product principles

- Core features work offline.
- No account or login is required.
- No backend or cloud API is required for V1.
- No advertisements in V1.
- No AI features in V1.
- Keep permissions and third-party SDKs to a minimum.
- Make study tracking dependable, especially when the app is backgrounded or the device is locked.
- Keep the UI simple, readable, and consistent.

### V1 scope exclusions

Do not add authentication, social feeds, chat, cloud sync, online leaderboards, location access, contacts access, Accessibility Service, screen monitoring, or advertising SDKs.

---

## 2. Final UI Design System

This design system is mandatory across every screen, dialog, chart, illustration, and reusable component.

### Color palette

| Purpose | Color |
|---|---|
| Main screen background | `#FFFFFF` — pure white |
| Main text | `#000000` — pure black |
| Primary button | `#123B52` — navy blue |
| Primary button text | `#FFFFFF` |
| Primary card surface | `#F0F0F0` — light grey |
| Secondary card surface | `#FFFFFF` |
| Card borders/dividers | Very light grey |
| Secondary text | Dark/mid grey |
| Primary icons | Black or navy |
| Inactive icons/navigation | Grey |
| Progress indicators/charts | Navy and grey |

### Strict restrictions

- Do not use teal.
- Do not use green, purple, orange, red, or other colorful accents.
- Do not use gradients.
- Do not use colorful backgrounds.
- Do not use unnecessary shadows.
- Do not introduce dark mode in V1.
- Do not give individual subjects arbitrary colorful card backgrounds.

### Visual direction

- Minimal, clean, professional, premium productivity aesthetic.
- Pure white app background.
- A balanced mix of white and light-grey cards.
- Rounded cards, approximately 16–20 px radius.
- Consistent horizontal padding, approximately 20–24 px.
- Consistent vertical spacing.
- Clear typography hierarchy; Inter or a comparable readable sans-serif is suitable.
- Black text, navy primary actions, and grey supporting surfaces.
- Android-friendly touch targets and accessible contrast.

---

## 3. Navigation Structure

Use four persistent bottom navigation destinations:

1. **Home** — dashboard and daily overview.
2. **Timer** — timer mode selection and session setup.
3. **Subjects** — subject list and subject details.
4. **Progress** — statistics, goals, streaks, and achievements.

Settings is opened from the Home screen's settings action.

Secondary routes include onboarding, session setup, active focus, session summary, subject details, planner, calendar, achievements, backup flows, and configuration screens.

Use GetX routing (`GetMaterialApp` and named routes or a clearly organized route table). Preserve predictable back navigation and prevent accidental loss of an active session.

---

## 4. Screen Inventory and Responsibilities

There are 15 primary screens. Supporting forms, dialogs, and states are listed separately.

### 4.1 Splash

**Purpose:** App launch and brand introduction.

- White background.
- Centered ParhaiMate logo and app name.
- Tagline: “Your Personal Study Companion”.
- Minimal navy loading indicator.
- Route returning users to Home and first-time users to Onboarding as appropriate.

### 4.2 Onboarding

**Purpose:** Explain the product to first-time users.

Three slides:

1. **Focus on What Matters** — focused study sessions.
2. **Plan Your Study Routine** — subjects and tasks.
3. **See Your Progress Grow** — study time, streaks, and goals.

Controls: Skip, Next, page indicators, Get Started. Illustrations must follow the monochrome/navy design system.

### 4.3 Home Dashboard

**Purpose:** Central overview of today's activity.

Include:
- Greeting and current date.
- Settings action.
- Weekly date selector.
- Today's Progress card: studied time, daily target, percentage, circular progress.
- Quick statistics: sessions, focus time, current streak.
- Quick actions: Start Studying, Add Subject, Plan Study.
- Today's Schedule with upcoming tasks.
- Recent Activity with completed sessions.
- Persistent bottom navigation.

Keep the dashboard informative but not crowded. Use realistic sample content in mockups, but connect displayed values to actual app state in implementation.

### 4.4 Study Timer

**Purpose:** Select a study timing mode.

Modes:
- Focus Timer — fixed duration countdown.
- Stopwatch — elapsed-time tracking.
- Pomodoro — focus and break cycles.

Include subject selector, duration presets (15, 25, 30, 45, 60 minutes), custom duration, and Timer Presets management. Primary action: Start Studying.

### 4.5 Session Setup

**Purpose:** Configure a session before it starts.

Fields:
- Subject (optional if the product allows an unassigned session).
- Timer mode.
- Duration/custom duration.
- Optional notes.
- Pomodoro focus duration, short break, long break, and cycles before long break.

Show a concise session summary and Start Session action. Only show Pomodoro-specific controls when Pomodoro is selected.

### 4.6 Active Focus

**Purpose:** Distraction-free live study experience.

Include:
- Subject and session mode.
- Large countdown or stopwatch.
- Navy circular progress ring.
- Current Pomodoro phase/cycle when applicable.
- Pause/Resume, Finish Session, Cancel Session.
- Confirmation dialogs for destructive or premature actions.

The timer must remain accurate across app backgrounding and process recreation. Do not rely on a decrementing in-memory counter.

### 4.7 Session Summary

**Purpose:** Present the result of a completed or ended session.

Include:
- Total study time.
- Subject and session type.
- Start/end time.
- Focus and break duration where applicable.
- Daily goal contribution and updated daily progress.
- Add/edit notes.
- Save/finish, Start Another Session, Back to Home.

Prevent duplicate session saving.

### 4.8 Subjects

**Purpose:** Browse and manage study subjects.

Include:
- Subject list.
- Add Subject action.
- Search.
- Active/archived filter.
- Subject cards with icon, name, total study time, weekly target, and progress.
- Empty state.

Add/edit subject fields: name, icon, optional neutral identifier, weekly target.

### 4.9 Subject Details

**Purpose:** View a subject's study history and progress.

Include:
- Subject name and edit/more actions.
- Total study time, session count, weekly target, progress.
- Daily, weekly, and monthly study totals.
- Average session duration.
- Weekly chart using navy and grey.
- Session history.
- Start Studying This Subject, Edit, Archive actions.

### 4.10 Study Planner

**Purpose:** Organize upcoming study tasks.

Include:
- Date selector.
- Today's, Upcoming, and Completed task groups.
- Task cards with title, subject, date/time, target duration, completion state.
- Add/edit task form.
- Complete, edit, and delete actions.

### 4.11 Calendar

**Purpose:** Explore study activity and scheduled tasks by date.

Include:
- Monthly calendar.
- Month/year navigation.
- Navy activity indicators on dates with activity.
- Selected-date summary: study duration and completed sessions.
- Scheduled and completed tasks for the selected date.

### 4.12 Statistics

**Purpose:** Explain study performance over time.

Filters: Week, Month, Year.

Metrics:
- Total study time.
- Total sessions.
- Average daily study time.
- Longest session.

Charts:
- Weekly study time bar chart.
- Subject distribution donut chart.
- Daily study activity line chart.

Additional insights:
- Most studied subject.
- Best study day.
- Average session duration.
- Concise performance summary.

Use navy, black, white, and grey only.

### 4.13 Goals & Streaks

**Purpose:** Encourage consistent study habits.

Include:
- Daily target, studied duration, remaining duration, circular progress.
- Weekly target and progress bar.
- Current and longest streak.
- Weekly activity calendar.
- Daily and weekly goal configuration.

Define streak qualification consistently (for example, a day qualifies when the user's configured daily target is reached; if a different rule is chosen, document it and apply it everywhere).

### 4.14 Achievements

**Purpose:** Show milestones and progress toward them.

Example achievements:
- First Session.
- Focus Starter — one hour studied.
- Consistent Learner — seven consecutive qualifying days.
- Study Champion — 25 sessions.
- Time Master — 50 study hours.
- Weekly Warrior — reach weekly goal.

Cards show icon, title, description, unlocked/locked state, and progress for locked achievements. Use monochrome icons and navy/grey styling.

### 4.15 Settings

**Purpose:** Manage preferences and local data.

Sections:

**General**
- Daily and weekly study goals.
- Default timer mode.
- Timer presets.
- Notification preferences.

**Data & Backup**
- Export backup.
- Import/restore backup.
- Export PDF report.
- Export CSV.

**App Information**
- About ParhaiMate.
- Privacy Policy.
- App version.

**Data Management**
- Clear study history.
- Delete all app data.

Destructive actions require clear confirmation.

---

## 5. Supporting Screens, Dialogs, and States

Design and implement these as secondary routes, dialogs, sheets, or states as appropriate:

1. Add Subject.
2. Edit Subject.
3. Add Study Task.
4. Edit Study Task.
5. Timer Preset Management.
6. Create/Edit Timer Preset.
7. Daily Goal Configuration.
8. Weekly Goal Configuration.
9. Backup Export Confirmation and progress.
10. Backup Import/Restore preview and confirmation.
11. Invalid/incompatible backup error.
12. Delete/Clear Data Confirmation.
13. Cancel Session Confirmation.
14. Finish Session Confirmation.
15. Empty Subjects State.
16. Empty Planner State.
17. Empty Session History State.
18. Notification Permission Explanation.
19. No Study Activity State.
20. Loading, validation, error, disabled, selected, and completed states.

---

## 6. Technology Stack

Use mutually compatible stable package versions at implementation time. Do not blindly pin old example versions.

- Flutter and Dart.
- **MVVM architecture.**
- **GetX** for reactive state management, dependency injection, and routing.
- SQLite using Drift for typed local database access and migrations.
- SharedPreferences for lightweight preferences only.
- Flutter Local Notifications for local reminders/session completion.
- `fl_chart` for statistics.
- `pdf` and `csv` for report export.
- `file_picker`, `path_provider`, and `share_plus` for backup/export workflows.
- `timezone` where required for notification scheduling.
- `build_runner` and Drift generator for generated database code.

Check package compatibility with the Flutter/Dart SDK and Android target before selecting versions.

---

## 7. Architecture — MVVM with GetX

Use feature-first Clean Architecture boundaries while keeping the presentation layer MVVM.

### MVVM responsibilities

**View**
- Flutter widgets and screens.
- Displays state exposed by the ViewModel.
- Sends user intents to the ViewModel.
- Must not contain business logic or direct database operations.

**ViewModel**
- Implemented using GetX controllers (for example, `HomeViewModel extends GetxController`).
- Owns screen/feature presentation state.
- Exposes reactive values using `Rx`, `Rxn`, and observable collections where appropriate.
- Handles input validation and user actions.
- Calls domain use cases/repository interfaces.
- Must not contain SQL queries or widget layout code.

**Model / Domain**
- Entities, value objects, enums, validation rules, and use cases.
- Repository contracts.
- Framework-independent business rules wherever practical.

**Data**
- Drift tables, DAOs, data sources, repository implementations, and DTO/mapping code.
- Converts database records to domain models and vice versa.

### Dependency injection

- Use GetX bindings or a centralized dependency registration approach.
- Register long-lived services/repositories at app scope.
- Register feature controllers at route/feature scope where practical.
- Use clear lifecycle cleanup; do not leave unnecessary permanent controllers.
- Avoid making every class a global singleton.

### Suggested feature structure

```text
lib/
  main.dart
  app/
    app.dart
    routes/
      app_pages.dart
      app_routes.dart
    bindings/
      initial_binding.dart
    lifecycle/
      app_lifecycle_handler.dart

  core/
    constants/
    errors/
    extensions/
    helpers/
    services/
    theme/
    utils/
    widgets/

  data/
    database/
      app_database.dart
      tables/
      daos/
      migrations/
    datasources/
    models/
    repositories/

  domain/
    entities/
    enums/
    repositories/
    usecases/

  features/
    onboarding/
      views/
      viewmodels/
      widgets/
    home/
      views/
      viewmodels/
      widgets/
    timer/
      views/
      viewmodels/
      widgets/
    subjects/
      views/
      viewmodels/
      widgets/
    planner/
      views/
      viewmodels/
      widgets/
    calendar/
      views/
      viewmodels/
      widgets/
    statistics/
      views/
      viewmodels/
      widgets/
    goals/
      views/
      viewmodels/
      widgets/
    achievements/
      views/
      viewmodels/
      widgets/
    backup/
      views/
      viewmodels/
      services/
    settings/
      views/
      viewmodels/
      widgets/

  shared/
    widgets/
    models/
    enums/

test/
  unit/
  widget/
  integration/
integration_test/
assets/
  icons/
  images/
  illustrations/
  fonts/
docs/
  ARCHITECTURE.md
  DATABASE_SCHEMA.md
  BACKUP_FORMAT.md
  PRIVACY_POLICY.md
  RELEASE_CHECKLIST.md
```

Keep responsibilities clear. If the team chooses a stricter feature-first data/domain/presentation nesting later, preserve the same MVVM boundaries.

---

## 8. Database Design

Use Drift over SQLite. Use migrations from the first release and enable foreign-key constraints.

### 8.1 `subjects`

- `id` — integer primary key.
- `name` — text.
- `color` — text or neutral style identifier; do not use colorful UI accents.
- `icon` — text identifier.
- `target_minutes` — integer.
- `created_at` — UTC Unix milliseconds.
- `updated_at` — UTC Unix milliseconds.
- `is_archived` — boolean.

### 8.2 `study_sessions`

- `id` — integer primary key.
- `subject_id` — nullable foreign key to subjects.
- `session_type` — focus, stopwatch, or pomodoro.
- `started_at` — UTC Unix milliseconds.
- `ended_at` — nullable UTC Unix milliseconds.
- `duration_seconds` — integer.
- `status` — active, completed, or cancelled.
- `notes` — nullable text.
- `created_at` — UTC Unix milliseconds.

### 8.3 `daily_goals`

- `id` — integer primary key.
- `date_key` — unique local date string (`YYYY-MM-DD`).
- `target_minutes` — integer.
- `created_at` — UTC Unix milliseconds.

### 8.4 `planner_tasks`

- `id` — integer primary key.
- `subject_id` — nullable foreign key.
- `title` — text.
- `scheduled_date` — local date string; store time separately if tasks support a time of day.
- `target_minutes` — integer.
- `is_completed` — boolean.
- `created_at` — UTC Unix milliseconds.
- `updated_at` — UTC Unix milliseconds.

### 8.5 `timer_presets`

- `id` — integer primary key.
- `name` — text.
- `focus_minutes` — integer.
- `short_break_minutes` — integer.
- `long_break_minutes` — integer.
- `cycles_before_long_break` — integer.
- `is_default` — boolean.

### 8.6 `achievements`

- `id` — integer primary key.
- `achievement_code` — unique text.
- `unlocked_at` — nullable UTC Unix milliseconds.

### 8.7 `streak_records`

- `id` — integer primary key.
- `date_key` — local date string.
- `study_minutes` — integer.
- `streak_qualified` — boolean.

### 8.8 `session_events`

- `id` — integer primary key.
- `session_id` — foreign key to study_sessions.
- `event_type` — text.
- `started_at` — UTC Unix milliseconds.
- `ended_at` — UTC Unix milliseconds.
- `duration_seconds` — integer.

### 8.9 `app_settings`

- `key` — text primary key.
- `value` — text.

### 8.10 `active_timer_state`

- `id` — integer primary key (single active state).
- `session_id` — nullable reference to study_sessions.
- `timer_mode` — text.
- `phase` — text.
- `target_end_at` — nullable UTC Unix milliseconds.
- `accumulated_seconds` — integer.
- `current_cycle` — integer.
- `is_paused` — boolean.
- `updated_at` — UTC Unix milliseconds.

### Database rules

- Add indexes for commonly queried subject IDs, session start times, scheduled dates, and date keys.
- Store timestamps consistently as UTC Unix milliseconds.
- Store user-calendar date keys as local `YYYY-MM-DD` strings.
- Use transactions when saving sessions and related events.
- Archive subjects rather than deleting historical context unexpectedly.
- Define safe foreign-key deletion behavior.
- Prevent duplicate achievement codes and duplicate daily goal dates.
- Document schema and migrations.
- Ensure statistics are derived consistently from completed sessions and valid session events.

---

## 9. Timer Engine — Critical Reliability Requirements

Never implement a countdown as a simple integer decremented once per second. That loses accuracy when the app is backgrounded or suspended.

### Countdown

- Persist a target end timestamp.
- Remaining time is calculated from the target end time and current time.
- UI ticker only refreshes the display; it is not the source of truth.
- On resume/relaunch, recalculate remaining time from persisted state.

### Stopwatch

- Persist accumulated seconds and the start time of the current running segment.
- Compute elapsed time from timestamps.
- Pause adds the current segment to accumulated time.

### State machine

```text
idle -> running -> paused -> running -> completed
                  \-> cancelled
running ----------> cancelled
```

- Persist active timer state.
- Ensure session completion is saved exactly once.
- Record pause/resume/break events where required.
- Schedule a local completion notification where supported.
- Handle Pomodoro focus/break transitions consistently.
- Recover safely after app process recreation.
- Do not depend on a Dart timer loop running in the background.
- Avoid permanent foreground services and full-screen intents for this use case.
- Avoid exact-alarm permission unless it is essential and policy-qualified; prefer suitable inexact scheduling initially.
- Test screen lock, app background, process termination, force-stop, reboot, timezone changes, and manual clock changes.
- Explain and handle Android limitations: force-stop can prevent scheduled work until the app is opened again.

---

## 10. Backup and Export

Support both manual backup and Android Auto Backup, with accurate user-facing explanations.

### 10.1 Manual backup

- Create a versioned JSON backup in a `.pmb` file (or a documented archive format).
- Include subjects, sessions, goals, planner tasks, achievements, streaks, timer presets, and appropriate settings.
- Define safe handling for an active timer during backup/restore; do not blindly resume a stale timer.
- Validate file format, version, required fields, and integrity before restoring.
- Use Android's document picker for import/export.
- Show a restore preview and explicit confirmation.
- Create a safety snapshot before replacing current data.
- Restore transactionally.
- Never silently overwrite existing data.
- Refresh application state after restore.

### 10.2 Android Auto Backup

- Configure Android backup rules for the intended database/preferences.
- Exclude caches, temporary files, and duplicate manual export files.
- Test real backup/restore behavior.
- Explain that Android Auto Backup is OS-managed and may transfer app data through Android backup services.
- Do not claim the app is exclusively local-only without qualifying this behavior in the privacy disclosure.
- Decide how active timer state behaves after device restore.

### 10.3 Reports

- PDF study report.
- CSV export for sessions and relevant summaries.
- Validate exported content and handle file/share errors gracefully.

---

## 11. Notifications and Permissions

- Use local notifications only where needed.
- Explain notification permission before requesting it.
- Provide settings to enable/disable reminders.
- Do not request unrelated permissions.
- Review Android notification and exact-alarm behavior for the selected target SDK.
- No location, contacts, microphone, camera, or Accessibility Service permission is needed for the planned V1 features.

---

## 12. Testing Strategy

### Unit tests

- Timer calculations and state transitions.
- Pause/resume and Pomodoro cycles.
- Session completion idempotency.
- Goal calculations.
- Streak qualification.
- Date and timezone calculations.
- Statistics aggregation.
- Backup validation and restore logic.

### Widget tests

- Main navigation.
- Dashboard cards and empty states.
- Timer controls and displayed states.
- Forms and validation.
- Subject/task lists.
- Dialog confirmation behavior.

### Integration tests

- Create subject -> start session -> complete session -> verify history.
- Planner task creation/completion.
- Daily goal and streak updates.
- Export -> import backup.
- App restart during active timer.
- Database migration.

### Device QA

- Physical Android device testing.
- Screen lock and background timer behavior.
- Process recreation and force-stop behavior.
- Airplane mode/offline operation.
- Different screen sizes and text scaling.
- Notification permission denied/granted.
- Date, timezone, month/year boundaries.
- Backup and restore.
- Release build stability and performance.

---

## 13. Development Roadmap — 8 Sprints

### Sprint 1 — Foundation

- Create Flutter project.
- Configure linting and app theme.
- Set up MVVM structure and GetX.
- Configure routing and dependency bindings.
- Build splash, onboarding, navigation shell, and reusable UI components.

### Sprint 2 — Database and Subjects

- Configure Drift and migrations.
- Implement tables, DAOs, repository contracts and implementations.
- Implement subject CRUD and archive behavior.
- Add settings persistence.

### Sprint 3 — Timer Engine

- Implement countdown, stopwatch, and Pomodoro engine.
- Persist active timer state.
- Implement lifecycle recovery and timer state machine.
- Add timer presets.

### Sprint 4 — Study Sessions

- Build session setup, active focus, and summary screens.
- Persist sessions and session events.
- Add completion notifications.
- Ensure exactly-once session saving.

### Sprint 5 — Student Productivity

- Build Home dashboard.
- Implement daily/weekly goals.
- Build planner and calendar.
- Connect subject progress and recent activity.

### Sprint 6 — Analytics

- Build weekly/monthly/yearly statistics.
- Implement charts and subject distribution.
- Implement streak calculation.
- Implement achievements and progress.

### Sprint 7 — Backup and Export

- Implement manual backup and restore.
- Configure Android Auto Backup.
- Implement PDF/CSV exports.
- Add data deletion and privacy documentation.

### Sprint 8 — QA and Release

- Complete unit, widget, and integration tests.
- Test timer reliability on real devices.
- Check performance, accessibility, and edge cases.
- Prepare app icon, screenshots, store listing, AAB, and release tracks.
- Verify current Google Play target API and testing requirements before submission.

---

## 14. Google Play and Privacy Readiness

Before release:

- Use original app name, logo, UI, illustrations, and code.
- Avoid copying competitors' branding, screenshots, or assets.
- Provide genuine functionality beyond a bare countdown timer.
- Minimize permissions and SDKs.
- Publish a privacy policy appropriate to actual app behavior.
- Complete Data Safety declarations accurately.
- Disclose Android Auto Backup behavior accurately.
- Verify current Play Console target API and account-specific testing requirements.
- Use Android App Bundle and Play App Signing as applicable.
- Test the exact release build.
- Do not assume approval is guaranteed.

---

## 15. Definition of Done

A feature is complete only when:

1. Its UI follows the finalized design system.
2. Its View contains no business/database logic.
3. Its GetX ViewModel owns the relevant presentation state and actions.
4. Business rules are in domain/use-case or service layers as appropriate.
5. Data access is behind repository interfaces.
6. Loading, empty, error, and success states are handled.
7. Data persists correctly where required.
8. Relevant unit/widget/integration tests pass.
9. Offline behavior is verified.
10. Navigation and lifecycle behavior are tested.
11. No unrelated permission or dependency is introduced.

---

## 16. Open Decisions to Confirm During Implementation

Do not silently invent product behavior where it affects data or user expectations. Propose a sensible default and document it for approval.

- Whether a study session may be started without selecting a subject.
- Whether daily goal completion requires reaching the full target or any minimum study duration.
- Whether streaks qualify by reaching the daily goal or by completing any study session.
- Whether planner tasks support a specific time of day or only a date.
- Whether deleting a subject archives it or removes it while preserving historical sessions.
- Whether active timer state is excluded from backup or restored as paused.
- Whether reminders are daily, task-based, or both.

**Core commitment:** ParhaiMate V1 is an offline-first, ad-free study productivity app built in Flutter using MVVM architecture and GetX, with the exact white/black/navy/light-grey visual identity specified above.
