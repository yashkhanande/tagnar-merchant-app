# Tagnar Merchant

The default app uses Firebase Authentication and the project's default
Firestore database. Google sign-in creates or refreshes
`merchants_new/{firebaseUid}`. The merchant then verifies their phone and must
complete the business onboarding form before anchors are fetched by matching
their `merchantId`. The
dashboard, requests, offers, payments, analytics, and chats load records for the
selected anchor. It never substitutes demo records when Firebase data is absent.

## Run it from Android Studio

1. Open this folder, `tagnar_merchant`, in Android Studio.
2. Make sure the Flutter and Dart plugins are installed. Set the Flutter SDK path
   to your Flutter installation (on this computer it is
   `/Users/yashkhanande/development/flutter`).
3. Open **Tools > Device Manager** and start an Android emulator. Alternatively,
   connect an Android phone with Developer options and USB debugging enabled.
4. Open the terminal at the bottom of Android Studio and run:

   ```sh
   flutter pub get
   flutter devices
   flutter run -d emulator-5554
   ```

   Replace `emulator-5554` with the Android device ID shown by `flutter devices`.
   The entry file is `lib/main.dart`. You can also select that file and press Run.
5. In a terminal run, press `r` after saving Dart code to hot reload; press `q` to
   stop. Use a full restart when changing dependencies or native Android files.

To run the credential-free demo explicitly, use:

```sh
flutter run -t lib/main_demo.dart
```

## Firestore data shape

Merchant profiles live in `merchants_new/{firebaseUid}`. Authentication writes
`uid`, `name`, `email`, `photoUrl`, optional verified `phoneNumber`, `createdAt`,
`lastLogin`, and `updatedAt`. Onboarding adds `businessName`, `businessAddress`,
`businessType`, `businessPhone`, `businessEmail`, `gstNumber`, `city`, `state`,
`country`, `postalCode`, and `onboardingCompleted`. All client profile writes are
restricted to the authenticated merchant's own UID.

Operational documents are stored in `merchant_requests`, `merchant_offers`,
`merchant_payments`, `merchant_interactions`, and `merchant_conversations`.
Every document must contain the `merchantId` and `anchorId`. Conversation
messages live under `merchant_conversations/{conversationId}/messages`.

The adapter accepts Firestore timestamps (or ISO strings) and expects the enum
values used by the app: request kind `brand|product`, request status
`pending|approved|declined`, payment status
`received|pending|failed|refunded`, chat role `brand|master|user`, and offer
decision `accepted|declined` (or no decision field). Amounts use integer paise;
offer rewards use integer rupees. Backend/Admin SDK processes must create the
records; client payments remain read-only.

Deploy the scoped rules before using live feature data:

```sh
firebase deploy --only firestore:rules --config firebase.merchant.json
```

Empty collections render normal empty states. Offline, denied, missing-index,
malformed-data, and unavailable-database errors render a retryable error instead
of showing fabricated data.

## Phone authentication setup

Before real SMS verification can work, enable the **Phone** provider in Firebase
Console under Authentication > Sign-in method. Then open Authentication settings
and allow the countries where SMS should be delivered (for `+91` numbers, enable
India). Register both the debug/release SHA-1 and SHA-256 certificate fingerprints
for the Android app, download the refreshed `google-services.json`, and rebuild.
Use Firebase test phone numbers during development to avoid sending real SMS.

If Flutter is not found, add your Flutter `bin` folder to your PATH and reopen the
terminal. Run `flutter doctor -v` for installation diagnostics. If it reports
unaccepted Android licenses, run `flutter doctor --android-licenses` and review
the prompts. No external console setup is needed for the demo.

## Check the demo

- **Dashboard:** shows the linked anchor, payment totals, pending requests, active
  offers, sample interactions, and recent payments. Tap a metric or the analytics
  button to explore further.
- **Requests:** search a brand, product, category, or request ID. Combine type and
  status filters. Tap a request for details. The Offer inbox is below the list.
- **Offers:** use **Review incoming offer** on Dashboard or **Review offer** in
  Requests. Tap **Accept** or **Decline**. The response is saved locally and the
  buttons disappear. Restart the app and use **View response** to check it stayed
  saved. **Later** closes the popup without answering. Demo acceptance makes the
  offer active but does not create a payment.
- **Payments:** choose dates and a status, then open a transaction. The headline
  sums Received records within the selected dates; a status filter only changes
  the list. There is no payment collection or status-changing action.
- **Analytics:** open **View interaction analytics** on Dashboard. Try Today,
  7 days, 30 days, All time, and Custom. Counts are sample events, not unique
  people, revenue attribution, or actual tracked activity.
- **Chats:** filter Brands, Masters, or Users; open a conversation to clear its
  unread count. Type a message and press Send. Messages are marked Local, retained
  after restarting, and never delivered to another person.
- **Profile:** shows the single fixed anchor. Open **Confirm phone number**,
  enter a number including `+` and country code, and tap **Get demo code**. Enter
  `123456` and tap **Confirm demo code**. Try an incorrect code first to see the
  error. Codes expire after five minutes. No SMS is sent; this is not real
  authentication or proof that you own the number.
- **State previews:** tap the sliders icon (**Demo tools**) at the top. Preview
  empty data or an error; **Try again** or **Normal demo / reload** restores the
  normal view. Reload shows the loading state. These previews do not erase data.

Demo fixtures are dated relative to the first launch and keep those dates on
later launches, so offer expiry is stable. To start the demo completely fresh,
use Android Settings > Apps > tagnar_merchant > Storage > Clear storage (this
removes this app's local demo decisions, messages, and phone confirmation).

## Project layout

```text
lib/main.dart                    Credential-free demo entry point
lib/main_firebase.dart           Preserved previous Firebase entry point
lib/core/models.dart             Typed immutable display data
lib/core/merchant_repository.dart Backend replacement boundary
lib/core/data/                   Demo fixtures, repository, local storage
lib/features/shell/              Navigation and GetX controller
lib/features/dashboard/          Dashboard and date-filtered analytics
lib/features/requests/           Request list, details, offer popup
lib/features/payments/           Read-only transaction records
lib/features/chats/              Conversation list and local messaging
lib/features/profile/            Single anchor profile and demo OTP
lib/shared/widgets/              Reusable UI and date/status filters
lib/pages/widgets/               Existing dashboard theme/card reused
lib/controller/, lib/services/   Preserved existing Firebase architecture
```

The only added dependency is `shared_preferences` 2.5.3, for device-local demo
storage. Its [official documentation](https://pub.dev/packages/shared_preferences)
explains that it is simple preference storage; it must not be used as the
production authority for offer decisions, authentication, or payments. Repository
writes are serialized and checked before updating the demo UI. Tests substitute
an in-memory store and do not need native plugins or Firebase.

The old Firebase flow is preserved in `lib/main_firebase.dart`; it is **not** the
completed stages 2–5. Its Google sign-in/onboarding behavior and existing Firebase
project are outside stage 1 verification. The default entry point does not
initialize Firebase or call those services. Android's Google services Gradle
plugin is applied only when `android/app/google-services.json` exists, so demo
builds also work without that file.

## Repeat the checks

```sh
dart format lib test
flutter analyze
flutter test
flutter build apk --debug
```

The Android APK is written to `build/app/outputs/flutter-apk/app-debug.apk`.
Do not use this debug build as a production release.

See [the staged plan and assumptions](docs/IMPLEMENTATION_PLAN.md) for the
remaining stages and questions about request direction, role permissions, and
backend security. Stage 2 will reuse Firebase Auth/Firestore and document the
console steps for real phone authentication and one-anchor assignment. Stages
3–5 will enforce merchant isolation, atomic offer responses, chat membership,
server notifications, authoritative received-payment records, and real analytics.
