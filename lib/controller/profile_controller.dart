import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:tagnar_merchant/controller/auth_controller.dart';

class ProfileController extends GetxController {
  final AuthController authController = Get.find<AuthController>();

  Rxn<User> user = Rxn<User>();

  @override
  void onInit() {
    user.bindStream(authController.user.stream);
    super.onInit();
  }
}