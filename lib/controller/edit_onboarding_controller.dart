import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/onboarding_details.dart';
import '../models/merchant.dart';
import '../services/onboarding_service.dart';

class EditOnboardingController extends GetxController {
  final String merchantId;
  final OnboardingService service;

  EditOnboardingController({required this.merchantId, required this.service});

  final formKey = GlobalKey<FormState>();

  final businessName = TextEditingController();
  final businessAddress = TextEditingController();
  final businessPhone = TextEditingController();
  final businessEmail = TextEditingController();
  final gstNumber = TextEditingController();
  final city = TextEditingController();
  final state = TextEditingController();
  final country = TextEditingController();
  final postalCode = TextEditingController();
  final businessType = BusinessType.none.obs;

  final isLoading = true.obs;
  final isSaving = false.obs;
  final loadError = RxnString();
  final saveError = RxnString();

  @override
  void onReady() {
    super.onReady();
    loadDetails();
  }

  Future<void> loadDetails() async {
    isLoading.value = true;
    loadError.value = null;

    try {
      final details = await service.load(merchantId);
      if (isClosed) return;

      businessName.text = details.businessName;
      businessAddress.text = details.businessAddress;
      businessType.value = details.businessType;
      businessPhone.text = details.businessPhone;
      businessEmail.text = details.businessEmail;
      gstNumber.text = details.gstNumber;
      city.text = details.city;
      state.text = details.state;
      country.text = details.country;
      postalCode.text = details.postalCode;
    } catch (_) {
      if (!isClosed) {
        loadError.value =
            'Could not load your business details. Please try again.';
      }
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }

  String? requiredField(String? value) {
    return value == null || value.trim().isEmpty
        ? 'This field is required.'
        : null;
  }

  String? optionalEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return null;
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Enter a valid email address or leave it blank.';
    }
    return null;
  }

  String? requiredBusinessType(BusinessType? value) {
    return value == null || value == BusinessType.none
        ? 'This field is required.'
        : null;
  }

  Future<void> save() async {
    if (isLoading.value || isSaving.value || loadError.value != null) {
      return;
    }

    if (!(formKey.currentState?.validate() ?? false)) return;

    FocusManager.instance.primaryFocus?.unfocus();

    isSaving.value = true;
    saveError.value = null;

    try {
      await service.save(
        merchantId,
        OnboardingDetails(
          businessName: businessName.text,
          businessAddress: businessAddress.text,
          businessType: businessType.value,
          businessPhone: businessPhone.text,
          businessEmail: businessEmail.text,
          gstNumber: gstNumber.text,
          city: city.text,
          state: state.text,
          country: country.text,
          postalCode: postalCode.text,
        ),
      );

      if (isClosed) return;

      isSaving.value = false;

      // Let PopScope rebuild before closing the saved form.
      await WidgetsBinding.instance.endOfFrame;

      if (!isClosed) {
        Get.back(result: true);
      }
    } catch (_) {
      if (!isClosed) {
        isSaving.value = false;
        saveError.value = 'Could not save your details. Please try again.';
      }
    }
  }

  @override
  void onClose() {
    businessName.dispose();
    businessAddress.dispose();
    businessPhone.dispose();
    businessEmail.dispose();
    gstNumber.dispose();
    city.dispose();
    state.dispose();
    country.dispose();
    postalCode.dispose();
    super.onClose();
  }
}
