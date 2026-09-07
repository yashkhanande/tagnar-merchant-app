import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/merchant_repository.dart';
import '../../core/models.dart';
import '../../pages/widgets/dashboard_theme.dart';
import '../../shared/widgets/merchant_widgets.dart';
import '../chats/chats_page.dart';
import '../dashboard/dashboard_page.dart';
import '../payments/payments_page.dart';
import '../profile/profile_page.dart';
import '../requests/requests_page.dart';
import 'merchant_controller.dart';

class MerchantShell extends StatefulWidget {
  const MerchantShell({super.key, required this.repository});
  final MerchantRepository repository;
  @override
  State<MerchantShell> createState() => _MerchantShellState();
}

class _MerchantShellState extends State<MerchantShell> {
  late final MerchantController _controller;
  @override
  void initState() {
    super.initState();
    _controller = MerchantController(widget.repository);
    _controller.load();
  }

  @override
  void dispose() {
    _controller.onDelete();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GetBuilder<MerchantController>(
    init: _controller,
    global: false,
    builder: (c) {
      final unread =
          c.data?.conversations.fold(0, (sum, chat) => sum + chat.unread) ?? 0;
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Tagnar',
            style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.5),
          ),
          actions: [
            const Center(child: StatusPill('MERCHANT')),
            IconButton(
              tooltip: 'Refresh demo data',
              onPressed: c.loading ? null : () => c.load(),
              icon: const Icon(Icons.refresh),
            ),
            PopupMenuButton<DemoScenario>(
              tooltip: 'Demo tools',
              icon: const Icon(Icons.tune),
              onSelected: (v) => c.load(scenario: v),
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: DemoScenario.normal,
                  child: Text('Normal demo / reload'),
                ),
                PopupMenuItem(
                  value: DemoScenario.empty,
                  child: Text('Preview empty state'),
                ),
                PopupMenuItem(
                  value: DemoScenario.error,
                  child: Text('Preview error state'),
                ),
              ],
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                color: DashboardTheme.iconBackground,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Text(
                  c.scenario == DemoScenario.normal
                      ? 'DEMO MODE · Sample data, saved locally'
                      : 'DEMO MODE · ${c.scenario.label} state preview',
                  style: const TextStyle(
                    fontSize: 12,
                    color: DashboardTheme.accent,
                  ),
                ),
              ),
              Expanded(
                child: c.loading
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Loading your demo shop…'),
                          ],
                        ),
                      )
                    : c.error != null
                    ? FeatureList(
                        children: [
                          EmptyState(
                            title: 'Could not load your shop',
                            message: c.error!,
                            icon: Icons.cloud_off_outlined,
                            action: FilledButton(
                              onPressed: () =>
                                  c.load(scenario: DemoScenario.normal),
                              child: const Text('Try again'),
                            ),
                          ),
                        ],
                      )
                    : IndexedStack(
                        index: c.selectedTab,
                        children: [
                          MerchantDashboardPage(controller: c),
                          RequestsPage(controller: c),
                          PaymentsPage(data: c.data!),
                          ChatsPage(controller: c),
                          MerchantProfilePage(controller: c),
                        ],
                      ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: c.selectedTab,
          onDestinationSelected: c.selectTab,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view_rounded),
              label: 'Dashboard',
            ),
            const NavigationDestination(
              icon: Icon(Icons.inbox_outlined),
              selectedIcon: Icon(Icons.inbox),
              label: 'Requests',
            ),
            const NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet),
              label: 'Payments',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: unread > 0,
                label: Text('$unread'),
                child: const Icon(Icons.chat_bubble_outline),
              ),
              selectedIcon: const Icon(Icons.chat_bubble),
              label: 'Chats',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      );
    },
  );
}
