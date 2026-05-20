import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SectionLabel extends StatelessWidget {
  final String text;
  final bool isDark;

  const SectionLabel({super.key, required this.text, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.spaceMono(
        color: isDark ? Colors.white38 : Colors.black38,
        fontSize: 9,
        letterSpacing: 2,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}