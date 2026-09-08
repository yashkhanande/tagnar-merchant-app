import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tagnar_merchant/core/data/demo_merchant_repository.dart';
import 'package:tagnar_merchant/core/data/demo_store.dart';
import 'package:tagnar_merchant/features/access/access_repository.dart';
import 'package:tagnar_merchant/features/dashboard/analytics_page.dart';
import 'package:tagnar_merchant/main.dart';
import 'package:tagnar_merchant/pages/widgets/dashboard_theme.dart';
import 'package:tagnar_merchant/shared/widgets/merchant_widgets.dart';

Future<void> launch(
  WidgetTester tester, {
  double width = 390,
  double scale = 1,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    MyApp(
      repository: DemoMerchantRepository(
        MemoryDemoStore(),
        delay: const Duration(milliseconds: 20),
      ),
    ),
  );
  expect(find.text('Loading your demo anchor…'), findsOneWidget);
  await tester.pumpAndSettle();
}

Future<void> tab(WidgetTester tester, String name) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(name)),
  );
  await tester.pumpAndSettle();
}

Future<void> reveal(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets('all five destinations work at a mobile size without Firebase', (
    tester,
  ) async {
    await launch(tester);
    expect(find.text('Hello, Aarav'), findsOneWidget);
    for (final entry in {
      'Requests': 'Brands & products',
      'Payments': 'Payment received',
      'Chats': 'Conversations',
      'Profile': 'Your merchant profile',
      'Dashboard': 'Hello, Aarav',
    }.entries) {
      await tab(tester, entry.key);
      expect(find.text(entry.value), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('request search, filters, empty state and details', (
    tester,
  ) async {
    await launch(tester);
    await tab(tester, 'Requests');
    await tester.enterText(
      find.widgetWithText(TextField, 'Search requests'),
      'earth',
    );
    await tester.pumpAndSettle();
    expect(find.text('1 requests · incoming demo proposals'), findsOneWidget);
    await tester.tap(find.text('Organic pantry collection'));
    await tester.pumpAndSettle();
    expect(find.text('Request ID'), findsOneWidget);
    expect(find.text('ANCHOR-PN-0142'), findsWidgets);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Search requests'),
      'no such product',
    );
    await tester.pumpAndSettle();
    await reveal(tester, find.text('No requests found'));
    expect(find.text('No requests found'), findsOneWidget);
    await reveal(tester, find.text('Clear filters'));
    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.widgetWithText(ChoiceChip, 'Products'),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Products'));
    await tester.tap(find.widgetWithText(ChoiceChip, 'Pending'));
    await tester.pumpAndSettle();
    expect(find.text('2 requests · incoming demo proposals'), findsOneWidget);
  });

  for (final action in ['Accept', 'Decline']) {
    testWidgets('offer $action saves once and removes response actions', (
      tester,
    ) async {
      await launch(tester);
      await reveal(tester, find.text('Review incoming offer'));
      await tester.tap(find.text('Review incoming offer'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(
          action == 'Accept' ? FilledButton : OutlinedButton,
          action,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Response saved on this device. You cannot respond again.'),
        findsOneWidget,
      );
      expect(find.widgetWithText(FilledButton, 'Accept'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, 'Decline'), findsNothing);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.text('Review incoming offer'), findsNothing);
    });
  }

  testWidgets(
    'payment dates and statuses filter records; details are read-only',
    (tester) async {
      await launch(tester);
      await tab(tester, 'Payments');
      expect(find.text('₹28,250.00'), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Today'));
      await tester.pumpAndSettle();
      expect(find.text('₹8,500.00'), findsWidgets);
      await reveal(tester, find.text('Leaf Home'));
      await tester.tap(find.text('Leaf Home'));
      await tester.pumpAndSettle();
      expect(find.text('Transaction details'), findsOneWidget);
      expect(find.text('TXN-2026-0186'), findsOneWidget);
      await reveal(tester, find.text('Close'));
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.widgetWithText(ChoiceChip, 'Failed'),
        -250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.widgetWithText(ChoiceChip, 'Failed'));
      await tester.pumpAndSettle();
      expect(find.text('No transactions found'), findsOneWidget);
    },
  );

  testWidgets('chat role filters, unread clear and local message send', (
    tester,
  ) async {
    await launch(tester);
    await tab(tester, 'Chats');
    await tester.tap(find.widgetWithText(ChoiceChip, 'Masters'));
    await tester.pumpAndSettle();
    expect(find.text('Daily Brew'), findsNothing);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Everyone'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Daily Brew'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Message'),
      'Can we discuss the display?',
    );
    await tester.pump();
    await tester.tap(find.byTooltip('Send message'));
    await tester.pumpAndSettle();
    expect(find.text('Can we discuss the display?'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.widgetWithText(TextField, 'Message'))
          .controller!
          .text,
      isEmpty,
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Can we discuss the display?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('demo OTP validates code and updates profile', (tester) async {
    await launch(tester);
    await tab(tester, 'Profile');
    await reveal(tester, find.text('Confirm phone number'));
    await tester.tap(find.text('Confirm phone number'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get demo code'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, '6-digit demo code'),
      '000000',
    );
    await tester.tap(find.text('Confirm demo code'));
    await tester.pumpAndSettle();
    expect(find.text('Incorrect demo code. Enter 123456.'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, '6-digit demo code'),
      '123456',
    );
    await tester.tap(find.text('Confirm demo code'));
    await tester.pumpAndSettle();
    expect(find.text('Phone confirmed in demo'), findsOneWidget);
    await tester.tap(find.text('Back to profile'));
    await tester.pumpAndSettle();
    expect(find.text('Demo confirmed'), findsOneWidget);
  });

  testWidgets('analytics dates alter sample event totals', (tester) async {
    await launch(tester);
    await reveal(tester, find.text('View interaction analytics'));
    await tester.tap(find.text('View interaction analytics'));
    await tester.pumpAndSettle();
    expect(find.text('User interactions'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Today'));
    await tester.pumpAndSettle();
    expect(find.text('42'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('live analytics switches between all and one anchor', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: DashboardTheme.data,
        home: const AnalyticsPage(
          interactions: [],
          live: true,
          initiallyAllAnchors: true,
          selectedAnchorId: 'anchor-a',
          anchors: [
            MerchantAnchor(
              id: 'anchor-a',
              name: 'Building',
              views: 10,
              gamePlayed: 2,
            ),
            MerchantAnchor(
              id: 'anchor-b',
              name: 'Lobby',
              views: 5,
              gamePlayed: 1,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('All anchor analytics'), findsOneWidget);
    expect(find.text('15'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('10 views'), findsOneWidget);
    expect(find.text('5 views'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Building · anchor-a').last);
    await tester.pumpAndSettle();
    expect(find.text('Anchor views'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('Anchor ID'), findsOneWidget);
    expect(find.text('anchor-a'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('error retry and empty state preview recover', (tester) async {
    await launch(tester);
    await tester.tap(find.byTooltip('Demo tools'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Preview error state'));
    await tester.pumpAndSettle();
    expect(find.text('Could not load your anchor'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Hello, Aarav'), findsOneWidget);
    await tester.tap(find.byTooltip('Demo tools'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Preview empty state'));
    await tester.pumpAndSettle();
    await tab(tester, 'Chats');
    expect(find.text('No conversations found'), findsOneWidget);
    await tab(tester, 'Payments');
    expect(find.text('₹0.00'), findsOneWidget);
  });

  testWidgets('compact phone supports increased text size', (tester) async {
    await launch(tester, width: 320, scale: 1.5);
    for (final name in [
      'Dashboard',
      'Requests',
      'Payments',
      'Chats',
      'Profile',
    ]) {
      await tab(tester, name);
      expect(tester.takeException(), isNull, reason: name);
    }
  });

  test('date filter includes both boundary days and excludes next day', () {
    final range = DateTimeRange(
      start: DateTime(2026, 9, 1),
      end: DateTime(2026, 9, 7),
    );
    expect(inDateRange(DateTime(2026, 9, 7, 23, 59), null, range), isTrue);
    expect(inDateRange(DateTime(2026, 9, 8), null, range), isFalse);
    expect(inDateRange(DateTime(2026, 8, 31, 23, 59), null, range), isFalse);
  });
}
