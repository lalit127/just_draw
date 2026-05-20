import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/kitchen_design.dart';
import '../providers/kitchen_design_provider.dart';
import '../providers/blueprint_provider.dart';
import '../widgets/step_progress_bar.dart';
import 'quotation_screen.dart';

class Kitchen3DPreviewScreen extends ConsumerStatefulWidget {
  const Kitchen3DPreviewScreen({super.key});

  @override
  ConsumerState<Kitchen3DPreviewScreen> createState() =>
      _Kitchen3DPreviewScreenState();
}

class _Kitchen3DPreviewScreenState
    extends ConsumerState<Kitchen3DPreviewScreen>
    with SingleTickerProviderStateMixin {
  int _selectedViewIndex = 0;
  bool _showFittingsOverlay = true;

  static const _viewLabels = ['Overview', 'Island View', 'Cabinet Wall'];
  static const _viewAngles = [null, 'Island View', 'Cabinet Wall'];

  // Per-view cache: key = view index, value = rendered bytes
  final Map<int, Uint8List> _renderCache = {};
  // Per-view loading state
  final Map<int, bool> _loadingViews = {};
  // Per-view error state
  final Map<int, String?> _viewErrors = {};

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(kitchenDesignProvider.notifier).goToStep(DesignStep.preview3d);
      // Generate Overview (index 0) on first load
      if (!_renderCache.containsKey(0)) {
        _generateViewRender(0);
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _generateViewRender(int viewIndex, {bool forceRegenerate = false}) async {
    // Skip if already cached (unless forced) or currently loading
    if (!forceRegenerate && _renderCache.containsKey(viewIndex)) return;
    if (_loadingViews[viewIndex] == true) return;

    setState(() {
      _loadingViews[viewIndex] = true;
      _viewErrors[viewIndex] = null;
    });

    try {
      final service = ref.read(geminiServiceProvider);
      final state = ref.read(kitchenDesignProvider);
      final design = state.design;
      final shape = design.shape ?? KitchenShape.island;

      final selectedAcc = design.accessories
          .where((a) => a.isSelected)
          .map((a) => a.name)
          .toList();

      String contextNotes = '';
      if (state.blueprintAnalysis != null) {
        contextNotes =
            ' Architectural Context: ${state.blueprintAnalysis!.description}.';
      }

      final bytes = await service.generateKitchenRender(
        kitchenShape: shape.label,
        finish: design.finish.label,
        accessories: selectedAcc,
        viewAngle: _viewAngles[viewIndex],
        additionalContext: contextNotes,
      );

      if (mounted) {
        setState(() {
          _renderCache[viewIndex] = bytes;
          _loadingViews[viewIndex] = false;
        });
        // Animate fade in for current view
        if (_selectedViewIndex == viewIndex) {
          _fadeController.forward(from: 0);
        }
      }
    } catch (e) {
      String message = 'Failed to generate render. Tap to retry.';
      if (e.toString().contains('429')) {
        message = 'AI is busy. Please wait and retry.';
      } else if (e.toString().contains('503')) {
        message = 'AI service temporarily unavailable. Retry in a minute.';
      } else if (e.toString().contains('Network') ||
          e.toString().contains('dio')) {
        message = 'Network error. Check connection.';
      }
      if (mounted) {
        setState(() {
          _loadingViews[viewIndex] = false;
          _viewErrors[viewIndex] = message;
        });
      }
    }
  }

  void _onTabSelected(int index) {
    if (_selectedViewIndex == index) return;
    setState(() => _selectedViewIndex = index);
    _fadeController.forward(from: 0);

    // Generate this view if not cached and not loading
    if (!_renderCache.containsKey(index) &&
        _loadingViews[index] != true) {
      _generateViewRender(index);
    }
  }

  void _reRenderCurrentView() {
    _generateViewRender(_selectedViewIndex, forceRegenerate: true);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(kitchenDesignProvider);
    final design = state.design;
    final shape = design.shape ?? KitchenShape.island;
    final fittings = state.numberedFittings;

    final currentBytes = _renderCache[_selectedViewIndex];
    final isCurrentLoading = _loadingViews[_selectedViewIndex] == true;
    final currentError = _viewErrors[_selectedViewIndex];

    // Count how many views are still loading (for global indicator)
    final anyLoading = _loadingViews.values.any((v) => v == true);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: const Icon(Icons.arrow_back,
                          color: Colors.white70, size: 18),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI 3D Preview',
                          style: GoogleFonts.spaceMono(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${shape.label} · ${design.finish.label}',
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Fittings overlay toggle
                  if (fittings.isNotEmpty)
                    GestureDetector(
                      onTap: () => setState(() => _showFittingsOverlay = !_showFittingsOverlay),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: _showFittingsOverlay
                              ? Colors.amber.withOpacity(0.3)
                              : Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _showFittingsOverlay
                                ? Colors.amber.withOpacity(0.5)
                                : Colors.white24,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _showFittingsOverlay
                                  ? Icons.pin_drop
                                  : Icons.pin_drop_outlined,
                              color: _showFittingsOverlay
                                  ? Colors.amber
                                  : Colors.white54,
                              size: 14,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${fittings.length}',
                              style: GoogleFonts.spaceMono(
                                color: _showFittingsOverlay
                                    ? Colors.amber
                                    : Colors.white54,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Re-render button
                  GestureDetector(
                    onTap: isCurrentLoading ? null : _reRenderCurrentView,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          isCurrentLoading
                              ? const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white54),
                                  ),
                                )
                              : const Icon(Icons.auto_awesome,
                                  color: Colors.white54, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            isCurrentLoading ? 'Rendering…' : 'Re-render',
                            style: GoogleFonts.spaceMono(
                              color: Colors.white54,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),

            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: StepProgressBar(
                currentStep: state.currentStepIndex,
                totalSteps: state.totalSteps,
                labels: DesignStep.values.map((s) => s.label).toList(),
                isDark: true,
              ),
            ),
            const SizedBox(height: 16),

            // ── Main Render Area ─────────────────────────────────────
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // ── Rendered image (cached, instant switch) ──────
                      if (currentBytes != null)
                        FadeTransition(
                          opacity: _fadeAnim,
                          child: Image.memory(
                            currentBytes,
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                          ),
                        )
                      // ── Loading shimmer ───────────────────────────────
                      else if (isCurrentLoading)
                        _RenderLoadingView(
                          shape: shape,
                          viewLabel: _viewLabels[_selectedViewIndex],
                        )
                      // ── Error with retry ──────────────────────────────
                      else if (currentError != null)
                        _RenderErrorView(
                          error: currentError,
                          shape: shape,
                          onRetry: () => _generateViewRender(
                            _selectedViewIndex,
                            forceRegenerate: true,
                          ),
                        )
                      // ── Initial placeholder ───────────────────────────
                      else
                        _RenderPlaceholderView(shape: shape),

                      // ── Numbered fitting markers overlay ────────────────
                      if (currentBytes != null && _showFittingsOverlay && fittings.isNotEmpty)
                        ..._buildNumberedFittingPins(fittings),

                      // ── Gradient overlay ─────────────────────────────
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 110,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.75),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // ── Bottom label ─────────────────────────────────
                      Positioned(
                        bottom: 14,
                        left: 16,
                        right: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${shape.label} Kitchen',
                              style: GoogleFonts.spaceMono(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${design.finish.label} finish · AI Generated',
                              style: GoogleFonts.spaceGrotesk(
                                color: Colors.white60,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Top badges ────────────────────────────────────
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Row(
                          children: [
                            // AI badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.auto_awesome,
                                      color: Colors.amber, size: 10),
                                  const SizedBox(width: 4),
                                  Text(
                                    'AI GENERATED',
                                    style: GoogleFonts.spaceMono(
                                      color: Colors.white54,
                                      fontSize: 8,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Blueprint badge
                            if (state.hasBlueprint) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.architecture,
                                        color: Colors.white, size: 10),
                                    const SizedBox(width: 4),
                                    Text(
                                      'FROM BLUEPRINT',
                                      style: GoogleFonts.spaceMono(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            // Pre-loading background badge
                            if (anyLoading && !isCurrentLoading) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(
                                      width: 8,
                                      height: 8,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'PRE-LOADING',
                                      style: GoogleFonts.spaceMono(
                                        color: Colors.white,
                                        fontSize: 7,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // ── Fittings count badge (top-right) ────────────
                      if (currentBytes != null && fittings.isNotEmpty)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2D5A27).withOpacity(0.85),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.settings_outlined,
                                    color: Colors.white, size: 11),
                                const SizedBox(width: 4),
                                Text(
                                  '${fittings.length} FITTINGS',
                                  style: GoogleFonts.spaceMono(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

            const SizedBox(height: 12),

            // ── View angle selector ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _viewLabels.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final label = entry.value;
                  final isActive = idx == _selectedViewIndex;
                  final isCached = _renderCache.containsKey(idx);
                  final isLoading = _loadingViews[idx] == true;
                  final hasError = _viewErrors[idx] != null;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => _onTabSelected(idx),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.white
                              : Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: hasError && !isActive
                                ? Colors.red.withOpacity(0.5)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Status dot
                            if (isLoading)
                              Padding(
                                padding: const EdgeInsets.only(right: 5),
                                child: SizedBox(
                                  width: 8,
                                  height: 8,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isActive
                                          ? Colors.black54
                                          : Colors.white38,
                                    ),
                                  ),
                                ),
                              )
                            else if (isCached && !isActive)
                              Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Container(
                                  width: 5,
                                  height: 5,
                                  decoration: const BoxDecoration(
                                    color: Colors.greenAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              )
                            else if (hasError && !isActive)
                              Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Container(
                                  width: 5,
                                  height: 5,
                                  decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            Text(
                              label,
                              style: GoogleFonts.spaceMono(
                                color:
                                    isActive ? Colors.black : Colors.white54,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 300.ms),

            const SizedBox(height: 10),

            // ── Numbered Fittings Legend Strip ──────────────────────────
            if (fittings.isNotEmpty)
              SizedBox(
                height: 56,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: fittings.length,
                  itemBuilder: (context, index) {
                    final fitting = fittings[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Numbered circle badge
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: _getFittingColor(fitting.number),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white24, width: 1),
                              ),
                              child: Center(
                                child: Text(
                                  '${fitting.number}',
                                  style: GoogleFonts.spaceMono(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  fitting.displayLabel,
                                  style: GoogleFonts.spaceMono(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  fitting.category,
                                  style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white38,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ).animate().fadeIn(delay: 250.ms, duration: 300.ms),

            const SizedBox(height: 10),

            // ── Bottom CTA ────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(
                  16, 0, 16, 10 + MediaQuery.of(context).padding.bottom),
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QuotationScreen()),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'VIEW QUOTATION',
                      style: GoogleFonts.spaceMono(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.receipt_long_outlined, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Numbered fitting pin markers ──────────────────────────────────
  List<Widget> _buildNumberedFittingPins(List<FittingItem> fittings) {
    // Pre-defined positions that mimic a kitchen layout view
    // These are fractional positions (0..1) relative to the render area
    final positions = <Offset>[
      const Offset(0.10, 0.12), // 1 - top-left (dishwasher area)
      const Offset(0.30, 0.10), // 2 - top-center-left (sink area)
      const Offset(0.65, 0.08), // 3 - top-right (upper cabinets)
      const Offset(0.85, 0.15), // 4 - right-top (range area)
      const Offset(0.45, 0.42), // 5 - center (island)
      const Offset(0.80, 0.38), // 6 - right-center
      const Offset(0.12, 0.45), // 7 - left-center (fridge/pantry)
      const Offset(0.12, 0.62), // 8 - left-lower
      const Offset(0.10, 0.78), // 9 - bottom-left (pantry)
      const Offset(0.50, 0.72), // 10
      const Offset(0.75, 0.65), // 11
      const Offset(0.35, 0.58), // 12
      const Offset(0.60, 0.28), // 13
      const Offset(0.92, 0.55), // 14
      const Offset(0.25, 0.35), // 15
    ];

    return fittings.take(positions.length).toList().asMap().entries.map(
      (entry) {
        final idx = entry.key;
        final fitting = entry.value;
        final pos = positions[idx];
        return Positioned(
          left: pos.dx * MediaQuery.of(context).size.width * 0.87,
          top: pos.dy * (MediaQuery.of(context).size.height * 0.38),
          child: _NumberedFittingPin(
            number: fitting.number,
            label: fitting.name,
            color: _getFittingColor(fitting.number),
          )
              .animate()
              .fadeIn(
                delay: Duration(milliseconds: 400 + 80 * idx),
                duration: 300.ms,
              )
              .scale(
                begin: const Offset(0.5, 0.5),
                end: const Offset(1.0, 1.0),
                delay: Duration(milliseconds: 400 + 80 * idx),
                duration: 300.ms,
              ),
        );
      },
    ).toList();
  }

  Color _getFittingColor(int number) {
    final colors = [
      const Color(0xFF2D5A27), // deep green
      const Color(0xFF3D7A35), // green
      const Color(0xFF4A8C3F), // mid green
      const Color(0xFF5B9E4A), // light green
      const Color(0xFF3B6B33), // forest
      const Color(0xFF4C7D42), // sage
      const Color(0xFF2B5526), // dark green
      const Color(0xFF3A7032), // emerald
      const Color(0xFF48893C), // grass
      const Color(0xFF567B4E), // olive
      const Color(0xFF2D5A27),
      const Color(0xFF3D7A35),
      const Color(0xFF4A8C3F),
      const Color(0xFF5B9E4A),
      const Color(0xFF3B6B33),
    ];
    return colors[(number - 1) % colors.length];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Numbered Fitting Pin Widget
// ─────────────────────────────────────────────────────────────────────────────

class _NumberedFittingPin extends StatelessWidget {
  final int number;
  final String label;
  final Color color;

  const _NumberedFittingPin({
    required this.number,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label tooltip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white24, width: 0.5),
          ),
          child: Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        // Connector line
        Container(width: 1, height: 8, color: Colors.white54),
        // Numbered circle
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '$number',
              style: GoogleFonts.spaceMono(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Render State Views
// ─────────────────────────────────────────────────────────────────────────────

class _RenderLoadingView extends StatefulWidget {
  final KitchenShape shape;
  final String viewLabel;
  const _RenderLoadingView({required this.shape, required this.viewLabel});

  @override
  State<_RenderLoadingView> createState() => _RenderLoadingViewState();
}

class _RenderLoadingViewState extends State<_RenderLoadingView>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  int _dotCount = 1;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    // Animate dots
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return false;
      setState(() => _dotCount = (_dotCount % 3) + 1);
      return mounted;
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) => Opacity(
              opacity: 0.4 + (_pulse.value * 0.6),
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 1.5),
                ),
                child: const Icon(Icons.view_in_ar_outlined,
                    color: Colors.white38, size: 32),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'GENERATING ${widget.viewLabel.toUpperCase()}${'.' * _dotCount}',
            style: GoogleFonts.spaceMono(
              color: Colors.white38,
              fontSize: 10,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'AI · ${widget.shape.label} kitchen',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white24,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 140,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: const LinearProgressIndicator(
                backgroundColor: Colors.white10,
                valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.white24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RenderErrorView extends StatelessWidget {
  final String error;
  final KitchenShape shape;
  final VoidCallback onRetry;

  const _RenderErrorView({
    required this.error,
    required this.shape,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.white38, size: 36),
          const SizedBox(height: 12),
          Text(
            'Render failed',
            style: GoogleFonts.spaceMono(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              style: GoogleFonts.spaceGrotesk(
                  color: Colors.white30, fontSize: 11),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(
                'Try Again',
                style: GoogleFonts.spaceMono(
                    color: Colors.white54, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RenderPlaceholderView extends StatelessWidget {
  final KitchenShape shape;
  const _RenderPlaceholderView({required this.shape});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.view_in_ar_outlined,
              color: Colors.white24, size: 48),
          const SizedBox(height: 12),
          Text(
            '3D CONCEPT VIEW',
            style: GoogleFonts.spaceMono(
              color: Colors.white38,
              fontSize: 12,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'AI rendering ${shape.label} kitchen…',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white24,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
