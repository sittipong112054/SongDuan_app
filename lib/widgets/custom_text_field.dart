import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    required this.hint,
    this.controller,
    this.obscure = false,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
  });

  final String hint;
  final TextEditingController? controller;
  final bool obscure;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType keyboardType;

  static const _fillColor = Color(0xFFF0F2F5);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            offset: const Offset(0, 6),
            blurRadius: 10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscure,
          style: GoogleFonts.nunitoSans(fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            prefixIconConstraints: const BoxConstraints(
              minWidth: 60,
              minHeight: 50,
            ),
            isDense: true,
            filled: true,
            fillColor: _fillColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 16,
            ),
            hintStyle: GoogleFonts.nunitoSans(
              color: Colors.black.withOpacity(0.35),
              fontWeight: FontWeight.w700,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }
}
