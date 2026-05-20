import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/blueprint_provider.dart';
import '../providers/kitchen_design_provider.dart';
import '../widgets/image_comparison_slider.dart';
import 'kitchen_type_screen.dart';

class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(blueprintProvider);

    if (!state.isDone ||
        state.sketchFile == null ||
        state.blueprintImageBytes == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
          ),
        ),
      );
    }

    final analysis = state.analysis;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── App Bar ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: const Icon(Icons.arrow_back,
                          color: Colors.black87, size: 18),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          analysis?.title ?? 'Blueprint',
                          style: GoogleFonts.spaceMono(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Drag slider to compare',
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.black38,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _NewSketchButton(
                    onTap: () {
                      ref.read(blueprintProvider.notifier).reset();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),

            // ── Comparison Slider ─────────────────────────────────────
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ImageComparisonSlider(
                      beforeImage: state.sketchFile!,
                      afterImage: state.blueprintImageBytes!,
                    ),
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 50.ms, duration: 400.ms),

            const SizedBox(height: 12),

            // ── Analysis Details ──────────────────────────────────────
            Expanded(
              flex: 3,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Measurements
                    if (analysis != null && analysis.measurements.isNotEmpty) ...[
                      Text(
                        'MEASUREMENTS',
                        style: GoogleFonts.spaceMono(
                          color: Colors.black38,
                          fontSize: 9,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: analysis.measurements
                              .map((m) => Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: _MeasurementChip(
                              label: m.label,
                              value: m.display,
                            ),
                          ))
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Detected elements
                    if (analysis != null && analysis.elements.isNotEmpty) ...[
                      Text(
                        'DETECTIONS',
                        style: GoogleFonts.spaceMono(
                          color: Colors.black38,
                          fontSize: 9,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: analysis.elements
                            .map((e) => _ElementTag(label: e))
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

            // ── START KITCHEN DESIGN CTA ─────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(
                  16, 0, 16, 12 + MediaQuery.of(context).padding.bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // Carry over the blueprint analysis and image to the kitchen design flow
                      if (analysis != null) {
                        ref.read(kitchenDesignProvider.notifier).startDesignFromBlueprint(
                          analysis, 
                          state.blueprintImageBytes!,
                        );
                      } else {
                        ref.read(kitchenDesignProvider.notifier).reset();
                      }
                      
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const KitchenTypeScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.kitchen_outlined, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'START KITCHEN DESIGN',
                          style: GoogleFonts.spaceMono(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }
}

class _MeasurementChip extends StatelessWidget {
  final String label;
  final String value;

  const _MeasurementChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.spaceMono(
              color: Colors.black38,
              fontSize: 8,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.spaceMono(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ElementTag extends StatelessWidget {
  final String label;

  const _ElementTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FA),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.black12),
      ),
      child: Text(
        label,
        style: GoogleFonts.spaceGrotesk(color: Colors.black87, fontSize: 12),
      ),
    );
  }
}

class _NewSketchButton extends StatelessWidget {
  final VoidCallback onTap;

  const _NewSketchButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7FA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.refresh, color: Colors.black54, size: 14),
            const SizedBox(width: 4),
            Text(
              'New',
              style: GoogleFonts.spaceMono(
                color: Colors.black54,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
