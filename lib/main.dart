import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'core/data/demo_merchant_repository.dart';
import 'core/data/demo_store.dart';
import 'core/merchant_repository.dart';
import 'features/shell/merchant_shell.dart';
import 'pages/widgets/dashboard_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.repository});
  final MerchantRepository? repository;

  @override
  Widget build(BuildContext context) => GetMaterialApp(
    title: 'Tagnar Merchant · Demo',
    debugShowCheckedModeBanner: false,
    theme: DashboardTheme.data,
    home: MerchantShell(
      repository: repository ?? DemoMerchantRepository(PreferencesDemoStore()),
    ),
  );
}
