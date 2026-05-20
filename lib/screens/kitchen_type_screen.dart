import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/kitchen_design.dart';
import '../providers/kitchen_design_provider.dart';
import '../widgets/step_progress_bar.dart';
import '../widgets/section_label.dart';
import 'drawer_fittings_screen.dart';

class KitchenTypeScreen extends ConsumerStatefulWidget {
  const KitchenTypeScreen({super.key});

  @override
  ConsumerState<KitchenTypeScreen> createState() => _KitchenTypeScreenState();
}

class _KitchenTypeScreenState extends ConsumerState<KitchenTypeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(kitchenDesignProvider.notifier).goToStep(DesignStep.kitchenType);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(kitchenDesignProvider);
    final notifier = ref.read(kitchenDesignProvider.notifier);
    final design = state.design;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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
                    child: Text(
                      'Kitchen Design',
                      style: GoogleFonts.spaceMono(
                        color: Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: StepProgressBar(
                currentStep: DesignStep.kitchenType.index,
                totalSteps: state.totalSteps,
                labels: DesignStep.values.map((s) => s.label).toList(),
              ),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      'Choose Kitchen Type',
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.black,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ).animate().fadeIn(duration: 300.ms),
                    const SizedBox(height: 4),
                    Text(
                      'Select the layout that matches your space',
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.black45,
                        fontSize: 13,
                      ),
                    ).animate().fadeIn(delay: 50.ms, duration: 300.ms),
                    const SizedBox(height: 24),

                    // Shape grid
                    GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: KitchenShape.values.length,
                      itemBuilder: (context, index) {
                        final shape = KitchenShape.values[index];
                        final isSelected = design.shape == shape;
                        return _ShapeCard(
                          shape: shape,
                          isSelected: isSelected,
                          onTap: () => notifier.selectShape(shape),
                        )
                            .animate()
                            .fadeIn(
                          delay: Duration(milliseconds: 80 * index),
                          duration: 300.ms,
                        );
                      },
                    ),

                    const SizedBox(height: 28),
                    const SectionLabel(text: 'CABINET FINISH'),
                    const SizedBox(height: 12),

                    // Finish selector
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: KitchenFinish.values.map((finish) {
                          final isSelected = design.finish == finish;
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: GestureDetector(
                              onTap: () => notifier.selectFinish(finish),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.black
                                      : const Color(0xFFF7F7FA),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.black
                                        : Colors.black12,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      finish.label,
                                      style: GoogleFonts.spaceGrotesk(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.black87,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '₹${finish.pricePerSqFt}/sqft',
                                      style: GoogleFonts.spaceMono(
                                        color: isSelected
                                            ? Colors.white70
                                            : Colors.black38,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 28),
                    const SectionLabel(text: 'CABINET DIMENSIONS'),
                    const SizedBox(height: 12),

                    // Cabinet sqft sliders
                    _CabinetSlider(
                      label: 'Base Cabinets',
                      value: design.baseCabinetSqFt,
                      min: 10,
                      max: 80,
                      onChanged: notifier.updateBaseCabinetSqFt,
                    ),
                    const SizedBox(height: 12),
                    _CabinetSlider(
                      label: 'Wall Cabinets',
                      value: design.wallCabinetSqFt,
                      min: 8,
                      max: 60,
                      onChanged: notifier.updateWallCabinetSqFt,
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomBar(
        enabled: design.shape != null,
        onNext: () {
          if (design.shape == null) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const DrawerFittingsScreen(),
            ),
          );
        },
      ),
    );
  }
}

class _ShapeCard extends StatelessWidget {
  final KitchenShape shape;
  final bool isSelected;
  final VoidCallback onTap;

  const _ShapeCard({
    required this.shape,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : const Color(0xFFF7F7FA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.black12,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(13)),
                child: Image.network(
                  shape.previewImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.black12,
                    child: const Icon(Icons.kitchen_outlined,
                        color: Colors.black38, size: 32),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shape.label,
                    style: GoogleFonts.spaceMono(
                      color: isSelected ? Colors.white : Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    shape.description,
                    style: GoogleFonts.spaceGrotesk(
                      color:
                      isSelected ? Colors.white60 : Colors.black45,
                      fontSize: 10,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CabinetSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _CabinetSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.black87,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${value.toStringAsFixed(0)} sq ft',
                style: GoogleFonts.spaceMono(
                  color: Colors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 2,
              thumbColor: Colors.black,
              activeTrackColor: Colors.black,
              inactiveTrackColor: Colors.black12,
              thumbShape:
              const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape:
              const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: ((max - min) / 2).round(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final bool enabled;
  final VoidCallback onNext;

  const _BottomBar({required this.enabled, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black.withOpacity(0.07))),
      ),
      child: ElevatedButton(
        onPressed: enabled ? onNext : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          disabledBackgroundColor: Colors.black12,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'NEXT: DRAWER FITTINGS',
              style: GoogleFonts.spaceMono(
                  fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, size: 16),
          ],
        ),
      ),
    );
  }
}
