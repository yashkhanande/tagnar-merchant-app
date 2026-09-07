# Tagnar merchant: staged implementation

## Inspection and stage 1 plan

The existing project is `tagnar_merchant`, using Flutter, GetX, Firebase Auth,
Firestore, Google Sign-In, and navy dashboard widgets. Preserve the existing
controllers/services/authentication flow and reuse the dashboard theme/cards.
The PDF's task 2 describes a Flutter merchant associated with one anchor; other
roles, Unity, maps, and AR are outside this app's scope.

1. Add a default, credential-free demo entry point; keep the previous Firebase
   entry point separately available for future integration work.
2. Add typed repository contracts, realistic fixtures, and local persistence.
   Build feature folders for Dashboard/analytics, Requests/offers, Payments,
   Chats, and Profile/phone confirmation, using GetX for shared state.
3. Implement navigation, search/status/type/date filters, detail views, unread
   counts, local messages, a one-response offer popup, and demo phone confirmation.
4. Make loading, empty, recoverable error, and success states reviewable. Test
   persistence, duplicate decisions, filtering, navigation, and local workflows;
   format, analyze, and run Flutter tests and an Android build where possible.

## Stage 1 assumptions

- All new screens use explicitly labelled demo data. No Firebase initialization,
  SMS, network messaging, notifications, money movement, or analytics ingestion
  happens through the demo entry point.
- One fixed merchant (Aarav Shah / Corner Market, Pune) has exactly one anchor,
  `ANCHOR-PN-0142`. No anchor selector or reassignment action is exposed.
- Currency is INR and display times use the device's local time. Fixtures use
  dates relative to the first launch, retained across restarts so offer expiry
  remains stable. Clearing app storage starts a fresh set of sample dates.
- For UI demonstration, requests are incoming brand/product placement proposals.
  Request statuses are informational; only offers have Accept/Decline actions.
  Accepted demo offers become active. These are provisional display assumptions,
  not backend permissions or commercial rules.
- Phone confirmation assumes SMS OTP in stage 2. Stage 1 accepts only the visible
  demo code `123456` after requesting a demo code; no SMS is sent and no real
  identity is verified. Phone input includes a country calling code.
- Brands, Masters, and Users have seeded conversations. Sending adds a local
  message; opening a conversation clears its demo unread count. No fake remote
  delivery or automatic replies are shown.
- Received payments are read-only records, including pending/failed/refunded
  examples. Only records marked Received contribute to received totals. The
  merchant cannot set transaction status or collect a payment.
- Offer decisions, local messages, read state, and demo phone confirmation are
  saved on this device using shared_preferences (the only new dependency).
  This is demo storage, not a production source of truth. Duplicate decisions
  are rejected in the repository as well as disabled in the UI. Backend atomic
  enforcement across devices is deferred to stage 3.
- Demo tools can simulate an empty response or a failed load without deleting
  stored data. Returning to normal restores the same local demo state.

## Later stages (not implemented now)

2. Reuse existing Firebase Auth/Firestore. Confirm sign-in methods, SMS regions,
   merchant eligibility, and who assigns the single anchor. Validate assignment
   on the backend; never trust a client-provided merchant/anchor ID.
3. Ask who creates/receives requests, who may transition statuses, offer expiry
   and acceptance rules, and what Masters may access. Use server-authorized,
   atomic, idempotent decisions and merchant isolation rules.
4. Confirm chat membership and allowed role pairs; enforce membership on every
   read/write and use server notification triggers with Firebase Messaging.
5. Read authoritative payment records from a trusted backend/webhook, never a
   client-declared success. Agree analytics event definitions and date/timezone
   rules before ingesting or aggregating real events.

Each later stage needs its own console setup, security rules/emulator checks,
formatting, analysis, and relevant tests. No console setup is needed for stage 1.
