import 'package:flutter/material.dart';

class AnimatedHamburgerIcon extends StatefulWidget {
  final bool isOpen;
  final VoidCallback? onTap;
  final Color color;
  final double size;
  final Duration duration;

  const AnimatedHamburgerIcon({
    super.key,
    this.isOpen = false,
    this.onTap,
    this.color = Colors.white,
    this.size = 24.0,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  State<AnimatedHamburgerIcon> createState() => _AnimatedHamburgerIconState();
}

class _AnimatedHamburgerIconState extends State<AnimatedHamburgerIcon>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _topLineAnimation;
  late Animation<double> _middleLineAnimation;
  late Animation<double> _bottomLineAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    // Animation pour la ligne du haut (rotation et translation)
    _topLineAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    ));

    // Animation pour la ligne du milieu (fade out/in)
    _middleLineAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));

    // Animation pour la ligne du bas (rotation et translation)
    _bottomLineAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    ));

    // Animation de rotation globale
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.125, // 45 degrés (1/8 de tour)
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    // Animation d'échelle pour l'effet de "pulse"
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
    ));
  }

  @override
  void didUpdateWidget(AnimatedHamburgerIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen != oldWidget.isOpen) {
      if (widget.isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value * 2 * 3.14159,
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: CustomPaint(
                  painter: HamburgerPainter(
                    color: widget.color,
                    topLineProgress: _topLineAnimation.value,
                    middleLineOpacity: _middleLineAnimation.value,
                    bottomLineProgress: _bottomLineAnimation.value,
                    strokeWidth: widget.size * 0.08,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class HamburgerPainter extends CustomPainter {
  final Color color;
  final double topLineProgress;
  final double middleLineOpacity;
  final double bottomLineProgress;
  final double strokeWidth;

  HamburgerPainter({
    required this.color,
    required this.topLineProgress,
    required this.middleLineOpacity,
    required this.bottomLineProgress,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final width = size.width;
    final height = size.height;
    final lineLength = width * 0.7;
    final centerX = width / 2;
    final centerY = height / 2;
    final lineSpacing = height * 0.25;

    // Ligne du haut - se transforme en partie haute du X
    final topStartX = centerX - lineLength / 2;
    final topEndX = centerX + lineLength / 2;
    final topY = centerY - lineSpacing;

    // Animation de la ligne du haut vers position X
    final topCurrentStartX = topStartX + (centerX - topStartX - lineLength * 0.3) * topLineProgress;
    final topCurrentEndX = topEndX - (topEndX - centerX - lineLength * 0.3) * topLineProgress;
    final topCurrentStartY = topY + (centerY - lineLength * 0.3 - topY) * topLineProgress;
    final topCurrentEndY = topY + (centerY + lineLength * 0.3 - topY) * topLineProgress;

    canvas.drawLine(
      Offset(topCurrentStartX, topCurrentStartY),
      Offset(topCurrentEndX, topCurrentEndY),
      paint,
    );

    // Ligne du milieu - disparaît progressivement
    if (middleLineOpacity > 0) {
      paint.color = color.withValues(alpha: middleLineOpacity);
      canvas.drawLine(
        Offset(centerX - lineLength / 2, centerY),
        Offset(centerX + lineLength / 2, centerY),
        paint,
      );
      paint.color = color; // Reset color
    }

    // Ligne du bas - se transforme en partie basse du X
    final bottomY = centerY + lineSpacing;
    final bottomCurrentStartX = topStartX + (centerX - topStartX - lineLength * 0.3) * bottomLineProgress;
    final bottomCurrentEndX = topEndX - (topEndX - centerX - lineLength * 0.3) * bottomLineProgress;
    final bottomCurrentStartY = bottomY + (centerY + lineLength * 0.3 - bottomY) * bottomLineProgress;
    final bottomCurrentEndY = bottomY + (centerY - lineLength * 0.3 - bottomY) * bottomLineProgress;

    canvas.drawLine(
      Offset(bottomCurrentStartX, bottomCurrentStartY),
      Offset(bottomCurrentEndX, bottomCurrentEndY),
      paint,
    );
  }

  @override
  bool shouldRepaint(HamburgerPainter oldDelegate) {
    return oldDelegate.topLineProgress != topLineProgress ||
        oldDelegate.middleLineOpacity != middleLineOpacity ||
        oldDelegate.bottomLineProgress != bottomLineProgress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

// Widget helper pour une utilisation plus simple
class SmartHamburgerIcon extends StatefulWidget {
  final VoidCallback? onTap;
  final Color color;
  final double size;
  final Duration duration;

  const SmartHamburgerIcon({
    super.key,
    this.onTap,
    this.color = Colors.white,
    this.size = 24.0,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  State<SmartHamburgerIcon> createState() => _SmartHamburgerIconState();
}

class _SmartHamburgerIconState extends State<SmartHamburgerIcon> {
  bool _isOpen = false;

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
    });
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedHamburgerIcon(
      isOpen: _isOpen,
      onTap: _toggle,
      color: widget.color,
      size: widget.size,
      duration: widget.duration,
    );
  }
}