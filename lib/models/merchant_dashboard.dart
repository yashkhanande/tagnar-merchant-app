enum DashboardPeriod {
  today('Today'),
  week('7 days'),
  month('30 days');

  const DashboardPeriod(this.label);

  final String label;
}

enum PaymentStatus { received, pending, failed, refunded }

class DashboardPayment {
  final String id;
  final String title;
  final String amountLabel;
  final DateTime createdAt;
  final PaymentStatus status;

  const DashboardPayment({
    required this.id,
    required this.title,
    required this.amountLabel,
    required this.createdAt,
    required this.status,
  });
}

// Display model. The controller/service formats amounts using the
// merchant's currency and calculates totals from authoritative data.
class MerchantDashboard {
  final String receivedLabel;
  final String pendingLabel;
  final int completedOrders;
  final String averageOrderLabel;
  final DateTime updatedAt;
  final List<DashboardPayment> payments;

  MerchantDashboard({
    required this.receivedLabel,
    required this.pendingLabel,
    required this.completedOrders,
    required this.averageOrderLabel,
    required this.updatedAt,
    required List<DashboardPayment> payments,
  }) : payments = List.unmodifiable(payments);
}

typedef DashboardLoader =
    Future<MerchantDashboard> Function(
      String merchantId,
      DashboardPeriod period,
    );
