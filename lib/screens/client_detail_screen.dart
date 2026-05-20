import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/kitchen_design_provider.dart';
import '../widgets/step_progress_bar.dart';
import 'proposal_screen.dart';

class ClientDetailsScreen extends ConsumerStatefulWidget {
  const ClientDetailsScreen({super.key});

  @override
  ConsumerState<ClientDetailsScreen> createState() =>
      _ClientDetailsScreenState();
}

class _ClientDetailsScreenState extends ConsumerState<ClientDetailsScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(kitchenDesignProvider.notifier).goToStep(DesignStep.clientDetails);
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  bool get _canProceed =>
      _nameCtrl.text.trim().isNotEmpty &&
          _phoneCtrl.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(kitchenDesignProvider);
    final notifier = ref.read(kitchenDesignProvider.notifier);

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
                  Text(
                    'Client Details',
                    style: GoogleFonts.spaceMono(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Client Information',
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.black,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ).animate().fadeIn(duration: 300.ms),
                    const SizedBox(height: 4),
                    Text(
                      'Required to generate the proposal package',
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.black45,
                        fontSize: 12,
                      ),
                    ).animate().fadeIn(delay: 50.ms, duration: 300.ms),
                    const SizedBox(height: 28),

                    _FieldLabel(text: 'CLIENT NAME *'),
                    const SizedBox(height: 8),
                    _InputField(
                      controller: _nameCtrl,
                      hint: 'e.g. Rajesh Kumar',
                      icon: Icons.person_outline,
                      onChanged: (v) {
                        notifier.updateClientName(v);
                        setState(() {});
                      },
                    ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

                    const SizedBox(height: 16),
                    _FieldLabel(text: 'PHONE NUMBER *'),
                    const SizedBox(height: 8),
                    _InputField(
                      controller: _phoneCtrl,
                      hint: '+91 XXXXX XXXXX',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      onChanged: (v) {
                        notifier.updateClientPhone(v);
                        setState(() {});
                      },
                    ).animate().fadeIn(delay: 150.ms, duration: 300.ms),

                    const SizedBox(height: 16),
                    _FieldLabel(text: 'EMAIL ADDRESS'),
                    const SizedBox(height: 8),
                    _InputField(
                      controller: _emailCtrl,
                      hint: 'client@email.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: notifier.updateClientEmail,
                    ).animate().fadeIn(delay: 200.ms, duration: 300.ms),

                    const SizedBox(height: 16),
                    _FieldLabel(text: 'PROJECT LOCATION'),
                    const SizedBox(height: 8),
                    _InputField(
                      controller: _locationCtrl,
                      hint: 'e.g. Vadodara, Gujarat',
                      icon: Icons.location_on_outlined,
                      onChanged: notifier.updateProjectLocation,
                    ).animate().fadeIn(delay: 250.ms, duration: 300.ms),

                    const SizedBox(height: 24),

                    // Proposal package preview
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F7FA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PROPOSAL PACKAGE INCLUDES',
                            style: GoogleFonts.spaceMono(
                              color: Colors.black38,
                              fontSize: 9,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...[
                            (Icons.architecture_outlined, 'Blueprint drawing'),
                            (Icons.view_in_ar_outlined, '3D Design concept'),
                            (Icons.receipt_long_outlined, 'Bill of Materials'),
                            (Icons.calculate_outlined, 'Full quotation with GST'),
                          ].map(
                                (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Icon(item.$1,
                                      color: Colors.black54, size: 16),
                                  const SizedBox(width: 10),
                                  Text(
                                    item.$2,
                                    style: GoogleFonts.spaceGrotesk(
                                      color: Colors.black87,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 300.ms, duration: 300.ms),

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
          onPressed: _canProceed
              ? () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const ProposalScreen()),
            );
          }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            disabledBackgroundColor: Colors.black12,
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
                'GENERATE PROPOSAL',
                style: GoogleFonts.spaceMono(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.auto_awesome_outlined, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.spaceMono(
        color: Colors.black38,
        fontSize: 9,
        letterSpacing: 1.5,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Icon(icon, color: Colors.black38, size: 18),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              onChanged: onChanged,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.black87,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.spaceGrotesk(
                  color: Colors.black26,
                  fontSize: 13,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
