import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tagnar_merchant/controller/auth_controller.dart';
import 'package:tagnar_merchant/controller/home_controller.dart';
import 'package:tagnar_merchant/pages/auth/login_page.dart';
import 'package:tagnar_merchant/pages/home_page.dart';
import 'package:tagnar_merchant/services/merchant_service.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});
  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AuthController());

    Get.put(AuthController());

    Get.lazyPut<MerchantService>(() => MerchantService());

    Get.lazyPut<HomeController>(() => HomeController());

    return Obx(() {
      if (controller.user.value != null) {
        return HomePage();
      } else {
        return LoginPage();
      }
    });
  }
}
