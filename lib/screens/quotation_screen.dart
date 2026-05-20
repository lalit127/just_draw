import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/kitchen_design.dart';
import '../providers/kitchen_design_provider.dart';
import '../widgets/step_progress_bar.dart';
import 'client_detail_screen.dart';

class QuotationScreen extends ConsumerStatefulWidget {
  const QuotationScreen({super.key});

  @override
  ConsumerState<QuotationScreen> createState() => _QuotationScreenState();
}

class _QuotationScreenState extends ConsumerState<QuotationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(kitchenDesignProvider.notifier).goToStep(DesignStep.quotation);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(kitchenDesignProvider);
    final design = state.design;

    final selectedAccessories = design.accessories.where((a) => a.isSelected).toList();
    final startIdx = 3 + design.drawers.length; 

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
                      'Quotation',
                      style: GoogleFonts.spaceMono(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    'JD-KT-2024',
                    style: GoogleFonts.spaceMono(
                      color: Colors.black38,
                      fontSize: 10,
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
            const SizedBox(height: 20),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Company header
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
                            'JUST DRAW ARCHITECTS & INTERIORS',
                            style: GoogleFonts.spaceMono(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Premium Modular Kitchen & Space Planning',
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white60,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _QuoteMetaChip(
                                label: 'LAYOUT',
                                value: design.shape?.label ?? '—',
                              ),
                              const SizedBox(width: 8),
                              _QuoteMetaChip(
                                label: 'FINISH',
                                value: design.finish.label,
                              ),
                              const SizedBox(width: 8),
                              _QuoteMetaChip(
                                label: 'DATE',
                                value: _today(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 300.ms),

                    const SizedBox(height: 20),

                    // BOM table header
                    _BomHeader(),
                    const SizedBox(height: 8),

                    // Base cabinets
                    _BomRow(
                      slNo: '1',
                      description: 'Base Cabinets',
                      qty: design.baseCabinetSqFt.toStringAsFixed(0),
                      unit: 'Sq Ft',
                      rate: design.finish.pricePerSqFt,
                      amount: design.baseCabinetTotal.round(),
                    ),
                    _BomRow(
                      slNo: '2',
                      description: 'Wall Cabinets',
                      qty: design.wallCabinetSqFt.toStringAsFixed(0),
                      unit: 'Sq Ft',
                      rate: (design.finish.pricePerSqFt * 0.9).round(),
                      amount: design.wallCabinetTotal.round(),
                    ),

                    // Drawers
                    ...design.drawers.asMap().entries.map((entry) {
                      final d = entry.value;
                      return _BomRow(
                        slNo: '${3 + entry.key}',
                        description: d.type.label,
                        qty: d.quantity.toString(),
                        unit: 'Sets',
                        rate: d.type.pricePerUnit,
                        amount: d.total,
                      );
                    }),

                    // Accessories
                    ...selectedAccessories.asMap().entries.map((entry) {
                      return _BomRow(
                        slNo: '${startIdx + entry.key}',
                        description: entry.value.name,
                        qty: '1',
                        unit: 'Nos',
                        rate: entry.value.price,
                        amount: entry.value.price,
                      );
                    }),

                    // Installation
                    _BomRow(
                      slNo: '${startIdx + selectedAccessories.length}',
                      description: 'Installation Charges',
                      qty: '1',
                      unit: 'Job',
                      rate: design.installationCharges.round(),
                      amount: design.installationCharges.round(),
                    ),

                    const SizedBox(height: 8),
                    const Divider(color: Colors.black12),
                    const SizedBox(height: 8),

                    // Totals
                    _TotalRow(
                      label: 'Sub Total',
                      amount: design.subTotal.round(),
                      isBold: false,
                    ),
                    const SizedBox(height: 6),
                    _TotalRow(
                      label: 'GST @ 18%',
                      amount: design.gst.round(),
                      isBold: false,
                    ),
                    const SizedBox(height: 8),

                    // Grand total
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'GRAND TOTAL',
                            style: GoogleFonts.spaceMono(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '₹${_fmtFull(design.grandTotal.round())}',
                            style: GoogleFonts.spaceMono(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Payment terms
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
                            'TERMS & CONDITIONS',
                            style: GoogleFonts.spaceMono(
                              color: Colors.black38,
                              fontSize: 9,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...[
                            '50% advance on confirmation.',
                            '40% before dispatch from factory.',
                            '10% after installation completion.',
                            'Electrical, plumbing, civil work excluded.',
                            'Delivery timeline: 15–20 working days.',
                          ].map(
                                (t) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('• ',
                                      style: TextStyle(
                                          color: Colors.black45, fontSize: 12)),
                                  Expanded(
                                    child: Text(
                                      t,
                                      style: GoogleFonts.spaceGrotesk(
                                        color: Colors.black54,
                                        fontSize: 12,
                                      ),
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
                  builder: (_) => const ClientDetailsScreen()),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
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
                'ADD CLIENT & SHARE',
                style: GoogleFonts.spaceMono(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.send_outlined, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _today() {
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year}';
  }

  String _fmtFull(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
    );
  }
}

class _BomHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text('Sl',
                style: GoogleFonts.spaceMono(
                    color: Colors.black38, fontSize: 9, letterSpacing: 0.5)),
          ),
          Expanded(
            flex: 3,
            child: Text('DESCRIPTION',
                style: GoogleFonts.spaceMono(
                    color: Colors.black38, fontSize: 9, letterSpacing: 0.5)),
          ),
          SizedBox(
            width: 30,
            child: Text('QTY',
                style: GoogleFonts.spaceMono(
                    color: Colors.black38, fontSize: 9, letterSpacing: 0.5),
                textAlign: TextAlign.center),
          ),
          SizedBox(
            width: 36,
            child: Text('UNIT',
                style: GoogleFonts.spaceMono(
                    color: Colors.black38, fontSize: 9, letterSpacing: 0.5),
                textAlign: TextAlign.center),
          ),
          SizedBox(
            width: 52,
            child: Text('RATE',
                style: GoogleFonts.spaceMono(
                    color: Colors.black38, fontSize: 9, letterSpacing: 0.5),
                textAlign: TextAlign.right),
          ),
          SizedBox(
            width: 60,
            child: Text('AMOUNT',
                style: GoogleFonts.spaceMono(
                    color: Colors.black38, fontSize: 9, letterSpacing: 0.5),
                textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}

class _BomRow extends StatelessWidget {
  final String slNo;
  final String description;
  final String qty;
  final String unit;
  final int rate;
  final int amount;

  const _BomRow({
    required this.slNo,
    required this.description,
    required this.qty,
    required this.unit,
    required this.rate,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(slNo,
                style: GoogleFonts.spaceMono(
                    color: Colors.black38, fontSize: 11)),
          ),
          Expanded(
            flex: 3,
            child: Text(description,
                style: GoogleFonts.spaceGrotesk(
                    color: Colors.black87,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
          SizedBox(
            width: 30,
            child: Text(qty,
                style: GoogleFonts.spaceMono(
                    color: Colors.black54, fontSize: 11),
                textAlign: TextAlign.center),
          ),
          SizedBox(
            width: 36,
            child: Text(unit,
                style: GoogleFonts.spaceGrotesk(
                    color: Colors.black38, fontSize: 10),
                textAlign: TextAlign.center),
          ),
          SizedBox(
            width: 52,
            child: Text(_fmt(rate),
                style: GoogleFonts.spaceMono(
                    color: Colors.black54, fontSize: 11),
                textAlign: TextAlign.right),
          ),
          SizedBox(
            width: 60,
            child: Text(_fmt(amount),
                style: GoogleFonts.spaceMono(
                    color: Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.w700),
                textAlign: TextAlign.right),
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

class _TotalRow extends StatelessWidget {
  final String label;
  final int amount;
  final bool isBold;

  const _TotalRow(
      {required this.label, required this.amount, required this.isBold});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.black54,
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          Text(
            '₹${_fmtFull(amount)}',
            style: GoogleFonts.spaceMono(
              color: Colors.black87,
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
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

class _QuoteMetaChip extends StatelessWidget {
  final String label;
  final String value;

  const _QuoteMetaChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.spaceMono(
                  color: Colors.white38, fontSize: 7, letterSpacing: 0.5)),
          Text(value,
              style: GoogleFonts.spaceMono(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
