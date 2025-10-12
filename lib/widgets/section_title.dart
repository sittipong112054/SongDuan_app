import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.notoSansThai(
        fontSize: 16.5,
        fontWeight: FontWeight.w900,
        color: const Color(0xFF2F2F2F),
      ),
    );
  }
}
