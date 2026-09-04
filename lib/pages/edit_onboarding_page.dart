import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/edit_onboarding_controller.dart';
import '../models/merchant.dart';
import 'widgets/dashboard_card.dart';
import 'widgets/dashboard_theme.dart';
import 'widgets/dark_blue_text_field.dart';

class EditOnboardingPage extends GetView<EditOnboardingController> {
  const EditOnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: DashboardTheme.data,
      child: Obx(() {
        final saving = controller.isSaving.value;
        final loading = controller.isLoading.value;
        final loadError = controller.loadError.value;
        final saveError = controller.saveError.value;

        return PopScope(
          canPop: !saving,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Business details'),
              leading: BackButton(
                onPressed: saving
                    ? null
                    : () => Navigator.of(context).maybePop(),
              ),
            ),
            body: SafeArea(
              child: loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        semanticsLabel: 'Loading business details',
                      ),
                    )
                  : loadError != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(loadError, textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: controller.loadDetails,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Try again'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 640),
                          child: Form(
                            key: controller.formKey,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Your business details',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Fill in missing details or update '
                                  'your existing information.',
                                  style: TextStyle(
                                    color: DashboardTheme.secondary,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                DashboardCard(
                                  child: Column(
                                    children: [
                                      DarkBlueTextField(
                                        controller: controller.businessName,
                                        label: 'Business name',
                                        prefixIcon: Icons.storefront_outlined,
                                        enabled: !saving,
                                        validator: controller.requiredField,
                                      ),
                                      const SizedBox(height: 18),
                                      DarkBlueTextField(
                                        controller: controller.businessAddress,
                                        label: 'Business address',
                                        prefixIcon: Icons.location_on_outlined,
                                        keyboardType: TextInputType.multiline,
                                        textInputAction:
                                            TextInputAction.newline,
                                        maxLines: 3,
                                        enabled: !saving,
                                        validator: controller.requiredField,
                                      ),
                                      const SizedBox(height: 18),
                                      DropdownButtonFormField<BusinessType>(
                                        initialValue:
                                            controller.businessType.value ==
                                                BusinessType.none
                                            ? null
                                            : controller.businessType.value,
                                        decoration: _fieldDecoration(
                                          'Business type',
                                          Icons.business_outlined,
                                        ),
                                        dropdownColor: const Color(0xFF193553),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                        items: BusinessType.values
                                            .where(
                                              (type) =>
                                                  type != BusinessType.none,
                                            )
                                            .map(
                                              (type) => DropdownMenuItem(
                                                value: type,
                                                child: Text(
                                                  _businessTypeLabel(type),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: saving
                                            ? null
                                            : (value) {
                                                if (value != null) {
                                                  controller
                                                          .businessType
                                                          .value =
                                                      value;
                                                }
                                              },
                                        validator:
                                            controller.requiredBusinessType,
                                      ),
                                      const SizedBox(height: 18),
                                      DarkBlueTextField(
                                        controller: controller.businessPhone,
                                        label: 'Business phone',
                                        prefixIcon: Icons.phone_outlined,
                                        keyboardType: TextInputType.phone,
                                        enabled: !saving,
                                        validator: controller.requiredField,
                                      ),
                                      const SizedBox(height: 18),
                                      DarkBlueTextField(
                                        controller: controller.businessEmail,
                                        label: 'Business email',
                                        prefixIcon: Icons.email_outlined,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        enabled: !saving,
                                        validator: controller.requiredField,
                                      ),
                                      const SizedBox(height: 18),
                                      DarkBlueTextField(
                                        controller: controller.gstNumber,
                                        label: 'GST number',
                                        prefixIcon: Icons.receipt_long_outlined,
                                        enabled: !saving,
                                        validator: controller.requiredField,
                                      ),
                                      const SizedBox(height: 18),
                                      DarkBlueTextField(
                                        controller: controller.city,
                                        label: 'City',
                                        prefixIcon: Icons.location_city,
                                        enabled: !saving,
                                        validator: controller.requiredField,
                                      ),
                                      const SizedBox(height: 18),
                                      DarkBlueTextField(
                                        controller: controller.state,
                                        label: 'State',
                                        prefixIcon: Icons.map_outlined,
                                        enabled: !saving,
                                        validator: controller.requiredField,
                                      ),
                                      const SizedBox(height: 18),
                                      DarkBlueTextField(
                                        controller: controller.country,
                                        label: 'Country',
                                        prefixIcon: Icons.public_outlined,
                                        enabled: !saving,
                                        validator: controller.requiredField,
                                      ),
                                      const SizedBox(height: 18),
                                      DarkBlueTextField(
                                        controller: controller.postalCode,
                                        label: 'Postal code',
                                        prefixIcon:
                                            Icons.markunread_mailbox_outlined,
                                        keyboardType: TextInputType.number,
                                        enabled: !saving,
                                        validator: controller.requiredField,
                                      ),
                                    ],
                                  ),
                                ),
                                if (saveError != null) ...[
                                  const SizedBox(height: 16),
                                  Semantics(
                                    liveRegion: true,
                                    child: Text(
                                      saveError,
                                      style: const TextStyle(
                                        color: Color(0xFFFCA5A5),
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: saving ? null : controller.save,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1D4ED8),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.all(16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    icon: saving
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(Icons.check_rounded),
                                    label: Text(
                                      saving
                                          ? 'Saving...'
                                          : 'Save business details',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        );
      }),
    );
  }

  static InputDecoration _fieldDecoration(String label, IconData icon) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color),
    );

    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFF193553),
      labelStyle: const TextStyle(color: Color(0xFFCBD5E1)),
      floatingLabelStyle: const TextStyle(color: Color(0xFF93C5FD)),
      errorStyle: const TextStyle(color: Color(0xFFFCA5A5)),
      prefixIcon: Icon(icon, color: const Color(0xFF93C5FD)),
      border: border(const Color(0xFF294B73)),
      enabledBorder: border(const Color(0xFF294B73)),
      disabledBorder: border(const Color(0xFF294B73)),
      focusedBorder: border(const Color(0xFF93C5FD)),
      errorBorder: border(const Color(0xFFFCA5A5)),
      focusedErrorBorder: border(const Color(0xFFFCA5A5)),
    );
  }

  static String _businessTypeLabel(BusinessType type) {
    switch (type) {
      case BusinessType.soleProprietorship:
        return 'Sole proprietorship';
      case BusinessType.partnership:
        return 'Partnership';
      case BusinessType.corporation:
        return 'Corporation';
      case BusinessType.llc:
        return 'LLC';
      case BusinessType.cooperative:
        return 'Cooperative';
      case BusinessType.nonprofit:
        return 'Nonprofit';
      case BusinessType.none:
        return 'Select business type';
    }
  }
}
