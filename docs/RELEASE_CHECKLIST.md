# ParhaiMate Release Checklist

## 1. Signing (already set up)

| File | Purpose | In git? |
|---|---|---|
| `android/app/upload-keystore.jks` | Upload key (alias `upload`, RSA 2048, valid ~27 years) | **No** (ignored by `**/*.jks`) |
| `android/key.properties` | Keystore path and passwords read by `android/app/build.gradle.kts` | **No** (ignored) |

**Back up both files now** (for example to a password manager plus an offline USB drive). With Play App Signing, Google holds the real app-signing key, so a lost upload key can be reset through Play Console support, but that takes days and blocks updates.

If `key.properties` is missing, release builds fall back to the debug key and print a warning. Play Console rejects debug-signed bundles.

Verify a bundle is signed with the upload key:

```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\jarsigner.exe" -verify -verbose:summary build\app\outputs\bundle\release\app-release.aab
```

## 2. Before each release

- [ ] Bump `version:` in `pubspec.yaml` (`1.0.1+2` → versionName 1.0.1, versionCode 2). versionCode must always increase.
- [ ] `flutter analyze` → no issues
- [ ] `flutter test` → all pass
- [ ] `flutter build appbundle --release`
- [ ] Install the release build on a real phone and test:
  - [ ] Focus timer finishes with screen locked → alert arrives, summary shows on return
  - [ ] Pomodoro: short breaks, long break after the last cycle, session saved once
  - [ ] Kill the app mid-session, reopen → timer restored correctly
  - [ ] Phone reboot during a session → alert still arrives
  - [ ] Deny notification permission → app still works
  - [ ] Backup export → import (Replace and Merge)
  - [ ] PDF report with an Urdu subject name
  - [ ] Airplane mode: everything works

## 3. Play Console (first release)

- [ ] Host the `legal-site/` folder on GitHub Pages (privacy policy, terms, support/data deletion)
- [ ] App content → Privacy policy URL
- [ ] App content → Data safety: **No data collected, no data shared**. Encryption in transit: not applicable (no network). Users can request deletion: yes (in-app delete)
- [ ] App content → Ads: **No ads**
- [ ] App content → Target audience: **13+** (avoids the Families policy)
- [ ] App content → Content rating questionnaire (Education/Productivity, no sensitive content)
- [ ] Store listing: 512×512 icon, 1024×500 feature graphic, at least 2 phone screenshots, short and full description (no competitor names or keyword stuffing)
- [ ] Play App Signing: enabled (default for new apps); upload `app-release.aab`
- [ ] **Personal developer account created after 13 Nov 2023:** closed test with at least 12 testers opted in for 14 continuous days, then apply for production access

## 4. Product rules (decided)

- Pomodoro session = N focus cycles, a short break between cycles, then one long break. The session is saved when the long break ends or the user taps Finish. Only focus time counts.
- Stopwatch sessions are auto-saved at 12 hours.
- Streak day = any completed study time that day (not the daily goal).
- Session alerts use inexact alarms only (no SCHEDULE_EXACT_ALARM / USE_EXACT_ALARM) to keep Play policy risk minimal. Android may deliver them several minutes late; the in-app timer and saved durations are always exact.
