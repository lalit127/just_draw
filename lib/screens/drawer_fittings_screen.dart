import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/kitchen_design.dart';
import '../providers/kitchen_design_provider.dart';
import '../widgets/step_progress_bar.dart';
import '../widgets/section_label.dart';
import 'accessories_screen.dart';

class DrawerFittingsScreen extends ConsumerStatefulWidget {
  const DrawerFittingsScreen({super.key});

  @override
  ConsumerState<DrawerFittingsScreen> createState() => _DrawerFittingsScreenState();
}

class _DrawerFittingsScreenState extends ConsumerState<DrawerFittingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(kitchenDesignProvider.notifier).goToStep(DesignStep.drawerFittings);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(kitchenDesignProvider);
    final notifier = ref.read(kitchenDesignProvider.notifier);
    final quantities = state.drawerQuantities;
    final design = state.design;

    final drawerTotal = quantities.entries
        .fold<int>(0, (sum, e) => sum + e.key.pricePerUnit * e.value);

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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Drawer Fittings',
                          style: GoogleFonts.spaceMono(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          design.shape?.label ?? '',
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.black38,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F7FA),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Text(
                      '₹${_formatPrice(drawerTotal)}',
                      style: GoogleFonts.spaceMono(
                        color: Colors.black87,
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
                currentStep: DesignStep.drawerFittings.index,
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
                      'Select Drawer Fittings',
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.black,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ).animate().fadeIn(duration: 300.ms),
                    const SizedBox(height: 4),
                    Text(
                      'All soft-close, full extension · Grey metal runners',
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.black45,
                        fontSize: 12,
                      ),
                    ).animate().fadeIn(delay: 50.ms, duration: 300.ms),
                    const SizedBox(height: 20),

                    const SectionLabel(text: 'STANDARD DRAWERS'),
                    const SizedBox(height: 12),
                    ...DrawerType.values
                        .where((d) =>
                    d != DrawerType.pullOutPantry &&
                        d != DrawerType.magicCorner)
                        .toList()
                        .asMap()
                        .entries
                        .map(
                          (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _DrawerCard(
                          type: entry.value,
                          quantity: quantities[entry.value] ?? 0,
                          onIncrement: () =>
                              notifier.incrementDrawer(entry.value),
                          onDecrement: () =>
                              notifier.decrementDrawer(entry.value),
                        )
                            .animate()
                            .fadeIn(
                          delay: Duration(
                              milliseconds: 60 * entry.key),
                          duration: 250.ms,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    const SectionLabel(text: 'SPECIALTY UNITS'),
                    const SizedBox(height: 12),
                    ...[DrawerType.pullOutPantry, DrawerType.magicCorner]
                        .asMap()
                        .entries
                        .map(
                          (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _DrawerCard(
                          type: entry.value,
                          quantity: quantities[entry.value] ?? 0,
                          onIncrement: () =>
                              notifier.incrementDrawer(entry.value),
                          onDecrement: () =>
                              notifier.decrementDrawer(entry.value),
                        )
                            .animate()
                            .fadeIn(
                          delay: Duration(
                              milliseconds: 60 * entry.key + 400),
                          duration: 250.ms,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F7FA),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'STANDARD FITTINGS',
                            style: GoogleFonts.spaceMono(
                              color: Colors.black38,
                              fontSize: 9,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...[
                            'Soft-close, full extension runners',
                            'Metal (slimline) sides · Grey finish',
                            'Load capacity: 40–60 kg per drawer',
                            'Anti-slip drawer liners recommended',
                          ].map(
                                (note) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: const BoxDecoration(
                                      color: Colors.black38,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    note,
                                    style: GoogleFonts.spaceGrotesk(
                                      color: Colors.black54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

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
                  builder: (_) => const AccessoriesScreen()),
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
                'NEXT: ACCESSORIES',
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
      ),
    );
  }

  String _formatPrice(int price) {
    if (price >= 100000) return '${(price / 100000).toStringAsFixed(1)}L';
    if (price >= 1000) return '${(price / 1000).toStringAsFixed(1)}K';
    return price.toString();
  }
}

class _DrawerCard extends StatelessWidget {
  final DrawerType type;
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _DrawerCard({
    required this.type,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = quantity > 0;
    final lineTotal = type.pricePerUnit * quantity;

    return AnimatedContainer(
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
              type.imageUrl,
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 52,
                height: 52,
                color: Colors.black12,
                child: const Icon(Icons.inbox_outlined,
                    color: Colors.black38, size: 22),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.label,
                  style: GoogleFonts.spaceMono(
                    color: isSelected ? Colors.white : Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  type.subtitle,
                  style: GoogleFonts.spaceGrotesk(
                    color: isSelected ? Colors.white60 : Colors.black45,
                    fontSize: 11,
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(height: 4),
                  Text(
                    '₹${_fmt(lineTotal)} total',
                    style: GoogleFonts.spaceMono(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              Text(
                '₹${_fmt(type.pricePerUnit)}',
                style: GoogleFonts.spaceMono(
                  color: isSelected ? Colors.white54 : Colors.black38,
                  fontSize: 9,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _StepBtn(
                    icon: Icons.remove,
                    onTap: quantity > 0 ? onDecrement : null,
                    isDark: isSelected,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      '$quantity',
                      style: GoogleFonts.spaceMono(
                        color: isSelected ? Colors.white : Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _StepBtn(
                    icon: Icons.add,
                    onTap: onIncrement,
                    isDark: isSelected,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(int price) {
    if (price >= 100000) return '${(price / 100000).toStringAsFixed(1)}L';
    if (price >= 1000) return '${(price / 1000).toStringAsFixed(1)}K';
    return price.toString();
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isDark;

  const _StepBtn(
      {required this.icon, required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(onTap != null ? 0.15 : 0.05)
              : Colors.black.withOpacity(onTap != null ? 0.08 : 0.04),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 14,
          color: isDark
              ? Colors.white.withOpacity(onTap != null ? 0.9 : 0.3)
              : Colors.black.withOpacity(onTap != null ? 0.7 : 0.3),
        ),
      ),
    );
  }
}
