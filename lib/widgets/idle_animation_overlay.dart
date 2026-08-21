import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

class IdleAnimationOverlay extends StatefulWidget {
  final Widget child;
  final Duration idleAfter;
  final bool enabled;

  const IdleAnimationOverlay({
    super.key,
    required this.child,
    this.enabled = true,
    this.idleAfter = const Duration(seconds: 30),
  });

  @override
  State<IdleAnimationOverlay> createState() => _IdleAnimationOverlayState();
}

class _IdleAnimationOverlayState extends State<IdleAnimationOverlay>
    with SingleTickerProviderStateMixin {
  Timer? _idleTimer;
  bool _showOverlay = false;
  late final AnimationController _controller;
  late List<_FloatItem> _items;
  final _rng = math.Random();

  static const _emojis = <String>[
    '\u{1FAC1}', // Lungs
    '\u{1F489}', // Syringe
    '\u{1FA7A}', // Stethoscope
    '\u{1F48A}', // Pill
    '\u{1FAC0}', // Anatomical Heart
    '\u{1F4A4}', // Zzz (Sleep)
    '\u{1FA78}', // Drop of blood
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    );
    _items = _buildItems();
    _resetIdleTimer();
  }

  List<_FloatItem> _buildItems() {
    return List.generate(12, (i) {
      return _FloatItem(
        emoji: _emojis[i % _emojis.length],
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        size: 26 + _rng.nextDouble() * 20,
        speedX: (_rng.nextDouble() * 0.4 + 0.12) * (_rng.nextBool() ? 1 : -1),
        speedY: (_rng.nextDouble() * 0.4 + 0.12) * (_rng.nextBool() ? 1 : -1),
        opacity: 0.16 + _rng.nextDouble() * 0.28,
        rotation: _rng.nextDouble() * math.pi * 2,
        spin: (_rng.nextDouble() * 0.4 + 0.1) * (_rng.nextBool() ? 1 : -1),
      );
    });
  }

  void _resetIdleTimer() {
    _idleTimer?.cancel();
    if (_showOverlay) {
      setState(() => _showOverlay = false);
      _controller.stop();
    }
    if (!widget.enabled) return;
    _idleTimer = Timer(widget.idleAfter, _onIdle);
  }

  void _onIdle() {
    if (!mounted) return;
    setState(() {
      _showOverlay = true;
      _items = _buildItems();
    });
    _controller.repeat();
  }

  void _onInteraction([_]) {
    _resetIdleTimer();
  }

  @override
  @override
  void didUpdateWidget(IdleAnimationOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      _resetIdleTimer();
    }
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onInteraction,
      onPointerMove: _onInteraction,
      onPointerSignal: _onInteraction,
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          if (_showOverlay)
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final size = MediaQuery.sizeOf(context);
                  // Advance physics each frame
                  for (final item in _items) {
                    item.x += item.speedX * 0.004;
                    item.y += item.speedY * 0.004;
                    item.rotation += item.spin * 0.02;

                    if (item.x < 0) {
                      item.x = 0;
                      item.speedX = item.speedX.abs();
                    } else if (item.x > 1) {
                      item.x = 1;
                      item.speedX = -item.speedX.abs();
                    }
                    if (item.y < 0) {
                      item.y = 0;
                      item.speedY = item.speedY.abs();
                    } else if (item.y > 1) {
                      item.y = 1;
                      item.speedY = -item.speedY.abs();
                    }
                  }

                  return CustomPaint(
                    size: size,
                    painter: _FloatPainter(items: List.from(_items), screen: size),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _FloatItem {
  final String emoji;
  double x;
  double y;
  final double size;
  double speedX;
  double speedY;
  final double opacity;
  double rotation;
  final double spin;

  _FloatItem({
    required this.emoji,
    required this.x,
    required this.y,
    required this.size,
    required this.speedX,
    required this.speedY,
    required this.opacity,
    required this.rotation,
    required this.spin,
  });
}

class _FloatPainter extends CustomPainter {
  final List<_FloatItem> items;
  final Size screen;

  _FloatPainter({
    required this.items,
    required this.screen,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final item in items) {
      final px = item.x * size.width;
      final py = item.y * size.height;

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(item.rotation);

      final tp = TextPainter(
        text: TextSpan(
          text: item.emoji,
          style: TextStyle(
            
            
            fontSize: item.size,
            color: const Color(0xFF38BDF8).withOpacity(item.opacity),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _FloatPainter oldDelegate) => true;
}