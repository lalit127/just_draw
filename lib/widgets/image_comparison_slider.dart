import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class ImageComparisonSlider extends StatefulWidget {
  final File beforeImage;
  final Uint8List afterImage;

  const ImageComparisonSlider({
    super.key,
    required this.beforeImage,
    required this.afterImage,
  });

  @override
  State<ImageComparisonSlider> createState() => _ImageComparisonSliderState();
}

class _ImageComparisonSliderState extends State<ImageComparisonSlider>
    with SingleTickerProviderStateMixin {
  double _sliderPosition = 0.5;
  late AnimationController _introController;
  late Animation<double> _introAnimation;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _introAnimation =
        Tween<double>(begin: 0.15, end: 0.5).animate(
          CurvedAnimation(parent: _introController, curve: Curves.easeOutCubic),
        )..addListener(() {
          setState(() => _sliderPosition = _introAnimation.value);
        });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _introController.forward();
    });
  }

  @override
  void dispose() {
    _introController.dispose();
    super.dispose();
  }

  void _updateSlider(double dx, double width) {
    setState(() {
      _sliderPosition = (dx / width).clamp(0.02, 0.98);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        return GestureDetector(
          onHorizontalDragUpdate: (d) =>
              _updateSlider(d.localPosition.dx, width),
          onTapDown: (d) => _updateSlider(d.localPosition.dx, width),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // ── After (blueprint) — full width background ──
                Positioned.fill(
                  child: Image.memory(widget.afterImage, fit: BoxFit.cover),
                ),

                // ── Before (sketch) — clipped to left side ──
                Positioned.fill(
                  child: ClipRect(
                    clipper: _LeftClipper(_sliderPosition),
                    child: Image.file(widget.beforeImage, fit: BoxFit.cover),
                  ),
                ),

                // ── Labels ──
                Positioned(
                  top: 16,
                  left: 16,
                  child: _Label(
                    text: 'SKETCH',
                    color: Colors.black.withOpacity(0.6),
                    textColor: Colors.white,
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: _Label(
                    text: 'BLUEPRINT',
                    color: Colors.black.withOpacity(0.6),
                    textColor: Colors.white,
                  ),
                ),

                // ── Divider line ──
                Positioned(
                  left: width * _sliderPosition - 1,
                  top: 0,
                  bottom: 0,
                  child: Container(width: 2, color: Colors.white),
                ),

                // ── Handle ──
                Positioned(
                  left: width * _sliderPosition - 22,
                  top: height / 2 - 22,
                  child: _SliderHandle(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LeftClipper extends CustomClipper<Rect> {
  final double fraction;
  const _LeftClipper(this.fraction);

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * fraction, size.height);

  @override
  bool shouldReclip(_LeftClipper old) => old.fraction != fraction;
}

class _SliderHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chevron_left, size: 16, color: Color(0xFF1A1A2E)),
          Icon(Icons.chevron_right, size: 16, color: Color(0xFF1A1A2E)),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;

  const _Label({
    required this.text,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
