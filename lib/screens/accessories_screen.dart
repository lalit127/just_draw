import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/kitchen_design.dart';
import '../providers/kitchen_design_provider.dart';
import '../widgets/step_progress_bar.dart';
import '../widgets/section_label.dart';
import 'interactive_preview_screen.dart';

class AccessoriesScreen extends ConsumerStatefulWidget {
  const AccessoriesScreen({super.key});

  @override
  ConsumerState<AccessoriesScreen> createState() => _AccessoriesScreenState();
}

class _AccessoriesScreenState extends ConsumerState<AccessoriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(kitchenDesignProvider.notifier).goToStep(DesignStep.accessories);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(kitchenDesignProvider);
    final notifier = ref.read(kitchenDesignProvider.notifier);
    final accessories = state.availableAccessories;

    final categories = accessories.map((a) => a.category).toSet().toList();

    final selectedTotal = accessories
        .where((a) => a.isSelected)
        .fold<int>(0, (sum, a) => sum + a.price);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
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
                      'Accessories & Hardware',
                      style: GoogleFonts.spaceMono(
                        color: Colors.black,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (selectedTotal > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '₹${_fmt(selectedTotal)}',
                        style: GoogleFonts.spaceMono(
                          color: Colors.white,
                          fontSize: 12,
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
                currentStep: DesignStep.accessories.index,
                totalSteps: state.totalSteps,
                labels: DesignStep.values.map((s) => s.label).toList(),
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kitchen Accessories',
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.black,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ).animate().fadeIn(duration: 300.ms),
                    const SizedBox(height: 4),
                    Text(
                      'Select the accessories to include in your kitchen',
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.black45,
                        fontSize: 12,
                      ),
                    ).animate().fadeIn(delay: 50.ms, duration: 300.ms),
                    const SizedBox(height: 24),

                    ...categories.asMap().entries.map((catEntry) {
                      final category = catEntry.value;
                      final categoryItems = accessories
                          .where((a) => a.category == category)
                          .toList();
                      final allSelected = categoryItems.every((a) => a.isSelected);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              SectionLabel(text: category.toUpperCase()),
                              GestureDetector(
                                onTap: () =>
                                    notifier.selectAllAccessoriesInCategory(
                                        category, !allSelected),
                                child: Text(
                                  allSelected ? 'Deselect all' : 'Select all',
                                  style: GoogleFonts.spaceGrotesk(
                                    color: Colors.black45,
                                    fontSize: 11,
                                    decoration:
                                    TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...categoryItems.asMap().entries.map(
                                (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _AccessoryCard(
                                accessory: entry.value,
                                onTap: () =>
                                    notifier.toggleAccessory(entry.value.id),
                              )
                                  .animate()
                                  .fadeIn(
                                delay: Duration(
                                    milliseconds:
                                    80 * catEntry.key +
                                        40 * entry.key),
                                duration: 250.ms,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    }),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(
          color: Colors.white,
          border:
          Border(top: BorderSide(color: Colors.black.withOpacity(0.07))),
        ),
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const InteractivePreviewScreen()),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'VIEW 3D PREVIEW',
                style: GoogleFonts.spaceMono(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.view_in_ar_outlined, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(int price) {
    if (price >= 100000) return '${(price / 100000).toStringAsFixed(1)}L';
    if (price >= 1000) return '${(price / 1000).toStringAsFixed(0)}K';
    return price.toString();
  }
}

class _AccessoryCard extends StatelessWidget {
  final KitchenAccessory accessory;
  final VoidCallback onTap;

  const _AccessoryCard({required this.accessory, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSelected = accessory.isSelected;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : const Color(0xFFF7F7FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.black12,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                accessoryImageUrl(accessory.id),
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 52,
                  height: 52,
                  color: Colors.black12,
                  child: const Icon(Icons.kitchen_outlined,
                      color: Colors.black38, size: 22),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    accessory.name,
                    style: GoogleFonts.spaceGrotesk(
                      color: isSelected ? Colors.white : Colors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    accessory.description,
                    style: GoogleFonts.spaceGrotesk(
                      color: isSelected ? Colors.white60 : Colors.black45,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${_fmt(accessory.price)}',
                  style: GoogleFonts.spaceMono(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.black26,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check,
                      color: Colors.black, size: 14)
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(int price) {
    if (price >= 100000) return '${(price / 100000).toStringAsFixed(1)}L';
    if (price >= 1000) return '${(price / 1000).toStringAsFixed(1)}K';
    return price.toString();
  }
}
