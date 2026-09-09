import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:tagnar_merchant/services/auth_service.dart';

class AuthController extends GetxController {
  final _authService = AuthService();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Rxn<User> user = Rxn<User>();

  @override
  void onInit() {
    user.bindStream(_firebaseAuth.authStateChanges());
    super.onInit();
  }

  var isLoading = false.obs;

  Future<void> createUser() async {
    isLoading.value = true;
    await _authService.createUser();
    isLoading.value = false;
  }

  Future<void> signOut() async {
    isLoading.value = true;
    await _authService.signOut();
    isLoading.value = false;
  }

  Future<void> deleteAccount() async {
    if (isLoading.value) return;

    try {
      isLoading.value = true;

      await _authService.deleteAccount();

      // Don't show snackbar here.
      // Firebase authStateChanges() will already emit null after deletion.
      // Your auth/root routing should handle moving to the login page.
    } on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'requires-recent-login':
          message =
              'For security, please sign in again before deleting your account.';
          break;

        case 'network-request-failed':
          message = 'Please check your internet connection and try again.';
          break;

        default:
          message = e.message ?? 'Unable to delete your account.';
      }

      if (Get.context != null) {
        Get.snackbar(
          'Delete Account Failed',
          message,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      if (Get.context != null) {
        Get.snackbar(
          'Delete Account Failed',
          'Something went wrong. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }
}
