import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:tagnar_merchant/services/merchant_service.dart';

class HomeController extends GetxController {
  final MerchantService merchantService =
      Get.find<MerchantService>();

  // Missing merchant fields
  final RxList<String> missingFields =
      <String>[].obs;

  // Whether we should show the profile completion card
  final RxBool isProfileIncomplete =
      false.obs;

  // Loading state
  final RxBool isLoading =
      false.obs;

  @override
  void onReady() {
    super.onReady();

    final uid =
        FirebaseAuth.instance.currentUser?.uid;

    if (uid != null) {
      loadMerchantProfile(uid);
    }
  }

  Future<void> loadMerchantProfile(
    String uid,
  ) async {
    try {
      isLoading.value = true;

      final merchant =
          await merchantService.getMerchant(uid);

      // Merchant document doesn't exist
      if (merchant == null) {
        missingFields.clear();
        isProfileIncomplete.value = true;
        return;
      }

      // Check every required field
      final missing =
          merchantService.getMissingFields(
        merchant,
      );

      // Update reactive list
      missingFields.assignAll(missing);

      // Show card if at least one field is missing
      isProfileIncomplete.value =
          missing.isNotEmpty;
    } catch (e) {
      print(
        'Error loading merchant profile: $e',
      );
    } finally {
      isLoading.value = false;
    }
  }
}