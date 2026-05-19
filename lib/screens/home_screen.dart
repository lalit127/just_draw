import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/blueprint_provider.dart';
import 'result_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 90,
      );
      if (pickedFile != null) {
        ref.read(blueprintProvider.notifier).setSketch(File(pickedFile.path));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 16),
                child: Text(
                  'SELECT SOURCE',
                  style: GoogleFonts.spaceMono(
                    color: Colors.black38,
                    fontSize: 10,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: Colors.black87),
                title: Text(
                  'Take a Photo',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: Colors.black87),
                title: Text(
                  'Upload from Gallery',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(blueprintProvider);

    // Listen to changes in generation state to navigate to result page
    ref.listen<BlueprintState>(blueprintProvider, (previous, next) {
      if (next.step == GenerationStep.done && next.blueprintImageBytes != null) {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, a, __) => const ResultScreen(),
            transitionsBuilder: (_, anim, __, child) => SlideTransition(
              position: Tween(begin: const Offset(1, 0), end: Offset.zero)
                  .animate(
                    CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
                  ),
              child: child,
            ),
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Subtle grey grid pattern
          Positioned.fill(
            child: Opacity(
              opacity: 0.4,
              child: CustomPaint(
                painter: GridPainter(),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title Header Section (Minimalistic)
                  Row(
                    children: [
                      const Icon(
                        Icons.architecture,
                        color: Colors.black87,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Blueprint AI',
                        style: GoogleFonts.spaceMono(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms),

                  const SizedBox(height: 36),

                  // Image Upload Card (Clean & Minimal)
                  GestureDetector(
                    onTap: state.isLoading ? null : _showImageSourcePicker,
                    child: Container(
                      height: 280,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F7FA),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: state.sketchFile != null
                              ? Colors.black12
                              : Colors.transparent,
                        ),
                      ),
                      child: DottedBorder(
                        color: state.sketchFile == null
                            ? Colors.black.withOpacity(0.12)
                            : Colors.transparent,
                        strokeWidth: 1.5,
                        dashPattern: const [6, 4],
                        borderType: BorderType.RRect,
                        radius: const Radius.circular(16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: state.sketchFile != null
                              ? Stack(
                                  children: [
                                    Positioned.fill(
                                      child: Image.file(
                                        state.sketchFile!,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    // Remove/delete button
                                    Positioned(
                                      bottom: 12,
                                      right: 12,
                                      child: FloatingActionButton.small(
                                        heroTag: 'remove_sketch',
                                        backgroundColor: Colors.white,
                                        elevation: 2,
                                        onPressed: () {
                                          ref.read(blueprintProvider.notifier).reset();
                                        },
                                        child: const Icon(Icons.delete_outline, color: Colors.black87, size: 20),
                                      ),
                                    ),
                                    // Retake / pick controls
                                    Positioned(
                                      top: 12,
                                      right: 12,
                                      child: Row(
                                        children: [
                                          _MiniActionBtn(
                                            icon: Icons.camera_alt_outlined,
                                            onTap: () => _pickImage(ImageSource.camera),
                                          ),
                                          const SizedBox(width: 8),
                                          _MiniActionBtn(
                                            icon: Icons.photo_library_outlined,
                                            onTap: () => _pickImage(ImageSource.gallery),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.add_photo_alternate_outlined,
                                        color: Colors.black38,
                                        size: 32,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Upload hand-drawn sketch',
                                        style: GoogleFonts.spaceGrotesk(
                                          color: Colors.black87,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          _PickButton(
                                            icon: Icons.camera_alt_outlined,
                                            label: 'Camera',
                                            onTap: () => _pickImage(ImageSource.camera),
                                          ),
                                          const SizedBox(width: 12),
                                          _PickButton(
                                            icon: Icons.photo_library_outlined,
                                            label: 'Gallery',
                                            onTap: () => _pickImage(ImageSource.gallery),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

                  const SizedBox(height: 24),

                  // Loading State with steps
                  if (state.isLoading) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F7FA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            state.stepLabel,
                            style: GoogleFonts.spaceMono(
                              color: Colors.black87,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(),
                    const SizedBox(height: 24),
                  ],

                  // Action Buttons (Black Minimalistic)
                  if (state.sketchFile != null && !state.isLoading)
                    ElevatedButton(
                      onPressed: () {
                        ref.read(blueprintProvider.notifier).generate();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.arrow_forward, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'GENERATE BLUEPRINT',
                            style: GoogleFonts.spaceMono(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 300.ms),

                  // Error card
                  if (state.hasError && state.errorMessage != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              state.errorMessage!,
                              style: GoogleFonts.spaceGrotesk(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(),
                  ],

                  // Instructions section
                  if (state.sketchFile == null) ...[
                    const SizedBox(height: 20),
                    const _HowItWorksSection(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.black87, size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.black87,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniActionBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MiniActionBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black12),
        ),
        child: Icon(icon, color: Colors.black87, size: 16),
      ),
    );
  }
}

class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection();

  static const steps = [
    (Icons.draw_outlined, 'Draw your sketch', 'Add dimensions on walls/rooms'),
    (Icons.upload_file_outlined, 'Upload it', 'Capture photo or pick from gallery'),
    (Icons.auto_awesome_outlined, 'AI Processing', 'Gemini reads dimensions & details'),
    (Icons.architecture_outlined, 'Get CAD Blueprint', 'Imagen generates scale floorplan'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HOW IT WORKS',
          style: GoogleFonts.spaceMono(
            color: Colors.black38,
            fontSize: 9,
            letterSpacing: 2,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        ...steps.asMap().entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Icon(
                  entry.value.$1,
                  color: Colors.black54,
                  size: 18,
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.value.$2,
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.black87,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      entry.value.$3,
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.black38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.03)
      ..strokeWidth = 0.5;

    const double step = 30.0;

    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
