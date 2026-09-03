import 'package:get/get.dart';
import 'package:tagnar_merchant/controller/home_controller.dart';
import 'package:tagnar_merchant/services/merchant_service.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(
      () => HomeController(),
    );
    Get.lazyPut<MerchantService>(
  () => MerchantService(),
);
  }
}