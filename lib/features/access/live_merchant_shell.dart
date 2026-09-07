import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/data/firestore_merchant_repository.dart';
import '../shell/merchant_shell.dart';
import '../../pages/widgets/dashboard_card.dart';
import '../../shared/widgets/merchant_widgets.dart';
import '../auth/merchant_session_controller.dart';

class LiveMerchantShell extends StatefulWidget {
  const LiveMerchantShell({super.key, required this.controller});
  final MerchantSessionController controller;
  @override
  State<LiveMerchantShell> createState() => _LiveMerchantShellState();
}

class _LiveMerchantShellState extends State<LiveMerchantShell> {
  int _tab = 0;
  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final user = c.identity!;
    final approved = c.shops.where((shop) => shop.approved).toList();
    final connected =
        c.anchor != null && c.selectedShop != null && c.accessError == null;
    if (connected) {
      final shop = c.selectedShop!;
      return MerchantShell(
        key: ValueKey('${shop.id}:${c.anchor!.id}'),
        live: true,
        repository: FirestoreMerchantRepository(
          firestore: FirebaseFirestore.instanceFor(
            app: FirebaseAuth.instance.app,
            databaseId: 'tagnar-merchant',
          ),
          auth: FirebaseAuth.instance,
          merchantId: user.uid,
          merchantName: user.name,
          shopId: shop.id,
          shopName: shop.name,
          shopAddress: shop.address,
          anchorId: c.anchor!.id,
          phone: user.verifiedPhone!,
        ),
        onSignOut: () => c.signOut(),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tagnar Merchant'),
        actions: [
          IconButton(
            tooltip: 'Refresh shop access',
            onPressed: c.loadingShops ? null : c.refreshAccess,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: c.signingOut ? null : c.signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: FeatureList(
          children: [
            const Notice('Firebase connected · Your merchant account'),
            if (c.error != null) Notice(c.error!, error: true),
            if (_tab == 4) ...[
              const SectionTitle('Merchant profile'),
              DashboardCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DetailLine('Name', user.name),
                    DetailLine('Google account', user.email),
                    DetailLine('Verified phone', user.verifiedPhone!),
                    const StatusPill('Verified'),
                    DetailLine(
                      'Merchant UID · give this to your Master',
                      user.uid,
                    ),
                    DetailLine('Approved shops', '${approved.length}'),
                    const Notice(
                      'A Master creates your shops and approves their anchor assignments. Contact your Master to add another shop.',
                    ),
                  ],
                ),
              ),
            ] else ...[
              SectionTitle(
                _tab == 0
                    ? 'Hello, ${user.name.split(' ').first}'
                    : ['Dashboard', 'Requests', 'Payments', 'Chats'][_tab],
                subtitle: 'Choose the shop you want to work with.',
              ),
              if (c.loadingShops)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (c.accessError != null)
                EmptyState(
                  title: 'Shop access unavailable',
                  message: c.accessError!,
                  icon: Icons.lock_outline,
                  action: FilledButton(
                    onPressed: c.refreshAccess,
                    child: const Text('Try again'),
                  ),
                ),
              if (!c.loadingShops && c.accessError == null && approved.isEmpty)
                EmptyState(
                  title: 'Waiting for a Master to assign your shops',
                  message:
                      'Your phone is verified. A Master must create and approve each shop anchor before it appears here.',
                  action: Column(
                    children: [
                      const Text('Merchant UID'),
                      SelectableText(user.uid),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: c.refreshAccess,
                        child: const Text('Check for approved shops'),
                      ),
                    ],
                  ),
                ),
              if (approved.isNotEmpty) ...[
                DashboardCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${approved.length} approved shops',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => _chooseShop(context),
                        icon: const Icon(Icons.storefront_outlined),
                        label: Text(c.selectedShop?.name ?? 'Choose a shop'),
                      ),
                      if (c.selectedShop != null)
                        DetailLine('Shop address', c.selectedShop!.address),
                      if (c.loadingAnchor)
                        const LinearProgressIndicator(
                          semanticsLabel: 'Verifying anchor access',
                        ),
                      if (connected) ...[
                        const StatusPill('Approved'),
                        DetailLine('Active anchor', c.anchor!.id),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (connected)
                  EmptyState(
                    title: switch (_tab) {
                      1 => 'Requests connection is next',
                      2 => 'Payment records are not connected yet',
                      3 => 'Chats are not connected yet',
                      _ => 'Your shop access is ready',
                    },
                    message: switch (_tab) {
                      1 =>
                        'Stage 3 connects requests and offer decisions for this shop.',
                      2 =>
                        'Stage 5 connects received-payment records. No payments are collected here.',
                      3 =>
                        'Stage 4 connects real-time conversations and notifications.',
                      _ =>
                        'You are signed in and authorised for this shop anchor. Requests, payments, chats and analytics will be connected in stages 3–5.',
                    },
                    icon: Icons.check_circle_outline,
                  ),
              ],
            ],
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() => _tab = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.inbox_outlined),
            label: 'Requests',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            label: 'Payments',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chats',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Future<void> _chooseShop(BuildContext context) async {
    final selectedId = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => ShopPicker(controller: widget.controller),
    );
    if (!mounted || selectedId == null) return;
    final candidates = widget.controller.shops.where(
      (shop) => shop.id == selectedId && shop.approved,
    );
    if (candidates.isNotEmpty) {
      await widget.controller.selectShop(candidates.first);
    }
  }
}

class ShopPicker extends StatefulWidget {
  const ShopPicker({super.key, required this.controller});
  final MerchantSessionController controller;
  @override
  State<ShopPicker> createState() => _ShopPickerState();
}

class _ShopPickerState extends State<ShopPicker> {
  String _query = '';
  @override
  Widget build(BuildContext context) {
    final shops = widget.controller.shops
        .where(
          (s) =>
              s.approved &&
              '${s.name} ${s.address} ${s.anchorId}'.toLowerCase().contains(
                _query.toLowerCase(),
              ),
        )
        .toList();
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .7,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SectionTitle('Choose an approved shop'),
              TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  labelText: 'Search shops or anchors',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: shops.isEmpty
                    ? const Center(
                        child: Text('No approved shops match your search.'),
                      )
                    : ListView.builder(
                        itemCount: shops.length,
                        itemBuilder: (context, index) {
                          final shop = shops[index];
                          return ListTile(
                            title: Text(shop.name),
                            subtitle: Text('${shop.address}\n${shop.anchorId}'),
                            isThreeLine: true,
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.pop(context, shop.id),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
