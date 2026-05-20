import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/kitchen_design.dart';
import '../providers/kitchen_design_provider.dart';
import '../widgets/step_progress_bar.dart';

class ProposalScreen extends ConsumerStatefulWidget {
  const ProposalScreen({super.key});

  @override
  ConsumerState<ProposalScreen> createState() => _ProposalScreenState();
}

class _ProposalScreenState extends ConsumerState<ProposalScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(kitchenDesignProvider.notifier).goToStep(DesignStep.proposal);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(kitchenDesignProvider);
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
                      'Proposal Ready',
                      style: GoogleFonts.spaceMono(
                        color: Colors.black,
                        fontSize: 14,
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
                currentStep: state.currentStepIndex,
                totalSteps: state.totalSteps,
                labels: DesignStep.values.map((s) => s.label).toList(),
              ),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Success icon
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.check,
                          color: Colors.white, size: 36),
                    )
                        .animate()
                        .scale(
                      begin: const Offset(0.5, 0.5),
                      end: const Offset(1, 1),
                      duration: 400.ms,
                      curve: Curves.elasticOut,
                    )
                        .fadeIn(duration: 300.ms),

                    const SizedBox(height: 16),
                    Text(
                      'Proposal Generated!',
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.black,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
                    const SizedBox(height: 6),
                    Text(
                      'Ready to share with ${design.clientName.isNotEmpty ? design.clientName : "your client"}',
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.black45,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 300.ms, duration: 300.ms),

                    const SizedBox(height: 28),

                    // Summary card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F7FA),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PROJECT SUMMARY',
                            style: GoogleFonts.spaceMono(
                              color: Colors.black38,
                              fontSize: 9,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 14),

                          if (design.clientName.isNotEmpty)
                            _SummaryRow(
                                icon: Icons.person_outline,
                                label: 'Client',
                                value: design.clientName),
                          if (design.projectLocation.isNotEmpty)
                            _SummaryRow(
                                icon: Icons.location_on_outlined,
                                label: 'Location',
                                value: design.projectLocation),
                          _SummaryRow(
                              icon: Icons.kitchen_outlined,
                              label: 'Layout',
                              value: design.shape?.label ?? '—'),
                          _SummaryRow(
                              icon: Icons.palette_outlined,
                              label: 'Finish',
                              value: design.finish.label),
                          _SummaryRow(
                              icon: Icons.inbox_outlined,
                              label: 'Drawers',
                              value:
                              '${design.drawers.fold<int>(0, (s, d) => s + d.quantity)} units'),
                          _SummaryRow(
                              icon: Icons.check_circle_outline,
                              label: 'Accessories',
                              value:
                              '${design.accessories.where((a) => a.isSelected).length} selected'),
                          const Divider(height: 20, color: Colors.black12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'GRAND TOTAL',
                                style: GoogleFonts.spaceMono(
                                  color: Colors.black,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '₹${_fmtFull(design.grandTotal.round())}',
                                style: GoogleFonts.spaceMono(
                                  color: Colors.black,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

                    const SizedBox(height: 24),

                    // What's included
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PACKAGE INCLUDES',
                            style: GoogleFonts.spaceMono(
                              color: Colors.white38,
                              fontSize: 9,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...[
                            'Blueprint design drawing',
                            '3D kitchen concept render',
                            'Engineering floor plan',
                            'Bill of Materials (BOM)',
                            'Itemized quotation with GST',
                          ].map(
                                (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle,
                                      color: Colors.white, size: 14),
                                  const SizedBox(width: 10),
                                  Text(
                                    item,
                                    style: GoogleFonts.spaceGrotesk(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

                    const SizedBox(height: 24),

                    // Share buttons
                    Text(
                      'SHARE WITH CLIENT',
                      style: GoogleFonts.spaceMono(
                        color: Colors.black38,
                        fontSize: 9,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ).animate().fadeIn(delay: 500.ms, duration: 300.ms),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _ShareButton(
                            icon: Icons.chat_outlined,
                            label: 'WhatsApp',
                            color: const Color(0xFF25D366),
                            onTap: () => _showShareSnack(
                                context, 'Sending via WhatsApp...'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ShareButton(
                            icon: Icons.email_outlined,
                            label: 'Email',
                            color: const Color(0xFF4285F4),
                            onTap: () => _showShareSnack(
                                context, 'Opening email draft...'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ShareButton(
                            icon: Icons.picture_as_pdf_outlined,
                            label: 'Export PDF',
                            color: const Color(0xFFE53935),
                            onTap: () => _showShareSnack(
                                context, 'Generating PDF...'),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 550.ms, duration: 300.ms),

                    const SizedBox(height: 24),

                    // Start new button
                    OutlinedButton(
                      onPressed: () {
                        ref.read(kitchenDesignProvider.notifier).reset();
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 50),
                        side: const BorderSide(color: Colors.black12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'NEW DESIGN',
                            style: GoogleFonts.spaceMono(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 600.ms, duration: 300.ms),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showShareSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.spaceGrotesk(color: Colors.white),
        ),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _fmtFull(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.black38, size: 16),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.black45,
              fontSize: 12,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ShareButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
