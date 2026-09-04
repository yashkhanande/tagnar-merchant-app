import 'package:flutter/material.dart';

class CompleteProfileCard extends StatelessWidget {
  final List<String> missingFields;
  final VoidCallback onCompleteProfile;

  const CompleteProfileCard({
    super.key,
    required this.missingFields,
    required this.onCompleteProfile,
  });

  @override
  Widget build(BuildContext context) {
    if (missingFields.isEmpty) {
      return const SizedBox.shrink();
    }

    const cardStart = Color(0xFF142D50);
    const cardEnd = Color(0xFF0B192E);
    const borderColor = Color(0xFF294B73);
    const iconBackground = Color(0xFF203F65);
    const accentColor = Color(0xFF93C5FD);
    const secondaryText = Color(0xFFCBD5E1);
    const chipBackground = Color(0xFF193553);
    const buttonColor = Color(0xFF1D4ED8);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cardStart, cardEnd],
        ),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.storefront_outlined,
                  color: accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Complete your business profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${missingFields.length} '
            '${missingFields.length == 1 ? 'detail is' : 'details are'} '
            'still missing.',
            style: const TextStyle(
              color: secondaryText,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: missingFields
                .map(
                  (field) => Chip(
                    label: Text(
                      field,
                      style: const TextStyle(
                        color: secondaryText,
                        fontSize: 12,
                      ),
                    ),
                    backgroundColor: chipBackground,
                    side: const BorderSide(color: borderColor),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              onPressed: onCompleteProfile,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text(
                'Complete Profile',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
