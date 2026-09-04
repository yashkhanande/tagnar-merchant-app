import 'package:flutter/material.dart';

class DarkBlueTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final IconData prefixIcon;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final int maxLines;
  final bool enabled;

  const DarkBlueTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.prefixIcon,
    this.hintText,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.maxLines = 1,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color),
      );
    }

    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLines: maxLines,
      validator: validator,
      cursorColor: const Color(0xFF93C5FD),
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        alignLabelWithHint: maxLines > 1,
        filled: true,
        fillColor: const Color(0xFF193553),
        labelStyle: const TextStyle(color: Color(0xFFCBD5E1)),
        floatingLabelStyle: const TextStyle(color: Color(0xFF93C5FD)),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
        errorStyle: const TextStyle(color: Color(0xFFFCA5A5)),
        errorMaxLines: 3,
        prefixIcon: Icon(prefixIcon, color: const Color(0xFF93C5FD)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: border(const Color(0xFF294B73)),
        enabledBorder: border(const Color(0xFF294B73)),
        disabledBorder: border(const Color(0xFF294B73)),
        focusedBorder: border(const Color(0xFF93C5FD)),
        errorBorder: border(const Color(0xFFFCA5A5)),
        focusedErrorBorder: border(const Color(0xFFFCA5A5)),
      ),
    );
  }
}
