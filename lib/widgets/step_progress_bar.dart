import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StepProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> labels;
  final bool isDark;

  const StepProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.labels,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (currentStep + 1) / totalSteps;
    final textColor = isDark ? Colors.white : Colors.black;
    final dimColor = isDark ? Colors.white38 : Colors.black38;
    final trackColor = isDark
        ? Colors.white.withOpacity(0.12)
        : Colors.black.withOpacity(0.08);
    final fillColor = isDark ? Colors.white : Colors.black;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              labels[currentStep.clamp(0, labels.length - 1)].toUpperCase(),
              style: GoogleFonts.spaceMono(
                color: textColor,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            Text(
              'Step ${currentStep + 1}/${totalSteps}',
              style: GoogleFonts.spaceMono(
                color: dimColor,
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 3,
              decoration: BoxDecoration(
                color: trackColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              widthFactor: progress,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: fillColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}