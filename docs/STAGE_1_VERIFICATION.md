# Stage 1 verification

Verified on 7 September 2026 with Flutter 3.38.9 and Dart 3.10.8.

| Check | Result |
| --- | --- |
| `dart format lib test` | Complete; final run made no changes |
| `flutter analyze` | No issues found |
| `flutter test --reporter expanded` | All 20 tests passed |
| `flutter build apk --debug` | Android debug APK built successfully |
| `flutter run -d emulator-5554 --no-resident` | Built, installed, and launched successfully |
| Android dashboard screenshot | Navy layout, totals, demo label, single anchor, and five navigation destinations visually checked |
| `git diff --check` | Passed |

The emulator is an Android arm64 device running Android 17 / API 37.
The APK is at `build/app/outputs/flutter-apk/app-debug.apk`.

## Automated coverage

- Five-tab navigation with no Firebase initialization in the Dart entry point.
- Requests: combined search/type/status filters, empty results, and details.
- Offers: both Accept and Decline, saved state across repository recreation,
  concurrent response rejection, no mutation after failed storage, retry,
  unknown offers, expiry, and removal of response actions after success.
- Payments: received-only totals, date/status filtering, details, and immutable
  display records. No client API exists to change payment status.
- Chats: role filters, local send, composer clearing, persisted messages/read
  state, unread isolation between conversations, and invalid input rejection.
- Demo phone confirmation: requesting a code, invalid number/code, number
  binding, expiry, one-time use, persisted confirmation, and profile update.
- Analytics: date filtering and inclusive date-range boundaries.
- Loading, empty preview, error preview, and retry recovery without deleting
  demo decisions.
- All primary screens at 320 logical pixels wide with 150% text scaling.

## Limits

- Repository persistence tests recreate the repository with a shared in-memory
  store. The Android launch exercised the native preferences plugin's initial
  read/write, but a full process-restart acceptance workflow was not manually
  tested on the emulator.
- The visual emulator check covered Dashboard; the other flows were exercised
  by Flutter widget tests. No physical Android device or iOS build was tested.
- The preserved Firebase entry point, Firebase rules, real authentication/SMS,
  notifications, remote chats, payment sources, and analytics ingestion were
  not tested or connected as part of stage 1.
- This is a debug build, not a signed production release. No external console
  changes or backend business rules were made.
