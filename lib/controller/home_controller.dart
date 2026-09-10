import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tagnar_merchant/controller/auth_controller.dart';
import 'package:tagnar_merchant/controller/edit_onboarding_controller.dart';
import 'package:tagnar_merchant/pages/edit_onboarding_page.dart';
import 'package:tagnar_merchant/pages/widgets/dashboard.dart';
import 'package:tagnar_merchant/services/merchant_service.dart';
import 'package:tagnar_merchant/services/onboarding_service.dart';

class HomeController extends GetxController {
  final MerchantService merchantService = Get.find<MerchantService>();
  final AuthController authController = Get.find<AuthController>();

  final missingFields = <String>[].obs;
  final isProfileIncomplete = false.obs;

  final isLoading = false.obs;
  final isRefreshing = false.obs;
  final isEditing = false.obs;
  final isSigningOut = false.obs;

  final profileError = RxnString();

  // Bridge to the existing stateful Dashboard widget.
  GlobalKey<DashboardState> dashboardKey = GlobalKey<DashboardState>();

  late final Worker _authWorker;

  String? _activeUid;
  int _profileRequest = 0;

  String get displayName {
    final name = authController.user.value?.displayName?.trim();

    return name == null || name.isEmpty ? 'Merchant' : name;
  }

  @override
  void onInit() {
    super.onInit();

    _authWorker = ever(authController.user, (_) => _handleAccountChange());
  }

  @override
  void onReady() {
    super.onReady();
    _handleAccountChange();
  }

  void _handleAccountChange() {
    final uid = authController.user.value?.uid;
    if (uid == _activeUid) return;

    _activeUid = uid;

    // Invalidate requests from the previous account.
    _profileRequest++;

    dashboardKey = GlobalKey<DashboardState>();

    missingFields.clear();
    isProfileIncomplete.value = false;
    profileError.value = null;
    isLoading.value = false;

    if (uid != null) {
      loadMerchantProfile(uid);
    }
  }

  Future<void> loadMerchantProfile(String uid) async {
    if (isClosed || authController.user.value?.uid != uid) return;

    final request = ++_profileRequest;

    isLoading.value = true;
    profileError.value = null;

    try {
      final merchant = await merchantService.getMerchant(uid);

      if (!_isCurrentRequest(request, uid)) return;

      if (merchant == null) {
        // The completion card hides when its list is empty.
        missingFields.assignAll(['Business profile']);
        isProfileIncomplete.value = true;
        return;
      }

      final missing = merchantService.getMissingFields(merchant);

      missingFields.assignAll(missing);
      isProfileIncomplete.value = missing.isNotEmpty;
    } catch (_) {
      if (!_isCurrentRequest(request, uid)) return;

      profileError.value =
          'Could not load your business profile. Please try again.';
    } finally {
      if (_isCurrentRequest(request, uid)) {
        isLoading.value = false;
      }
    }
  }

  bool _isCurrentRequest(int request, String uid) {
    return !isClosed &&
        request == _profileRequest &&
        authController.user.value?.uid == uid;
  }

  Future<void> refreshDashboard() async {
    if (isClosed || isRefreshing.value) return;

    final uid = authController.user.value?.uid;
    if (uid == null) return;

    isRefreshing.value = true;

    try {
      await Future.wait<void>([
        loadMerchantProfile(uid),
        dashboardKey.currentState?.refresh() ?? Future<void>.value(),
      ]);
    } catch (_) {
      _showError('Could not refresh your dashboard.');
    } finally {
      if (!isClosed) {
        isRefreshing.value = false;
      }
    }
  }

  Future<void> editBusiness({Future<void> Function()? openEditor}) async {
    if (isClosed || isEditing.value) return;

    final uid = authController.user.value?.uid;
    if (uid == null) return;

    isEditing.value = true;

    try {
      if (openEditor != null) {
        await openEditor();
      } else {
        await Get.to<bool>(
          () => const EditOnboardingPage(),
          binding: BindingsBuilder(() {
            Get.lazyPut<EditOnboardingController>(
              () => EditOnboardingController(
                merchantId: uid,
                service: OnboardingService(
                  firestore: FirebaseFirestore.instance,
                  functions: FirebaseFunctions.instanceFor(
                    app: FirebaseAuth.instance.app,
                    region: 'asia-south1',
                  ),
                  auth: FirebaseAuth.instance,
                ),
              ),
            );
          }),
        );
      }

      if (!isClosed && authController.user.value?.uid == uid) {
        await refreshDashboard();
      }
    } catch (_) {
      _showError('Could not open business details. Please try again.');
    } finally {
      if (!isClosed) isEditing.value = false;
    }
  }

  Future<void> signOut() async {
    if (isClosed || isSigningOut.value) return;

    isSigningOut.value = true;

    try {
      await authController.signOut();
    } catch (_) {
      _showError('Could not sign out. Please try again.');
    } finally {
      if (!isClosed) {
        isSigningOut.value = false;
      }
    }
  }

  void _showError(String message) {
    if (isClosed) return;

    Get.snackbar(
      'Something went wrong',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF142D50),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
    );
  }

  @override
  void onClose() {
    _authWorker.dispose();
    _profileRequest++;
    super.onClose();
  }
}
