import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/app_haptics.dart';

/// An individual stroke composed of points.
class SignatureStroke {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  SignatureStroke({
    required this.points,
    this.color = Colors.black,
    this.strokeWidth = 2.8,
  });
}

/// Custom painter that smooths strokes using quadratic Bézier curves.
class SignaturePainter extends CustomPainter {
  final List<SignatureStroke> strokes;
  final SignatureStroke? currentStroke;
  final bool drawBaseline;
  final Color baselineColor;

  SignaturePainter({
    required this.strokes,
    this.currentStroke,
    this.drawBaseline = true,
    this.baselineColor = const Color(0x33000000),
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (drawBaseline) {
      final linePaint = Paint()
        ..color = baselineColor
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      final y = size.height * 0.78;
      // Draw signature baseline guide
      canvas.drawLine(Offset(24, y), Offset(size.width - 24, y), linePaint);

      // Draw subtle "X" mark on the baseline
      final textPainter = TextPainter(
        text: TextSpan(
          text: '✕',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: baselineColor.withValues(alpha: 0.6),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(26, y - 18));
    }

    final allStrokes = [...strokes, if (currentStroke != null) currentStroke!];

    for (final stroke in allStrokes) {
      if (stroke.points.isEmpty) continue;

      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      if (stroke.points.length == 1) {
        canvas.drawCircle(stroke.points.first, stroke.strokeWidth / 2, paint);
        continue;
      }

      final path = Path();
      path.moveTo(stroke.points[0].dx, stroke.points[0].dy);

      for (int i = 1; i < stroke.points.length; i++) {
        final p0 = stroke.points[i - 1];
        final p1 = stroke.points[i];
        final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
        path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
      }

      final last = stroke.points.last;
      path.lineTo(last.dx, last.dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant SignaturePainter oldDelegate) => true;
}

/// Controller to manipulate and export signature strokes.
class SignatureController extends ChangeNotifier {
  final List<SignatureStroke> _strokes = [];
  SignatureStroke? _currentStroke;
  final Color strokeColor;
  final double strokeWidth;

  SignatureController({
    this.strokeColor = const Color(0xFF1E293B),
    this.strokeWidth = 2.8,
  });

  List<SignatureStroke> get strokes => List.unmodifiable(_strokes);
  SignatureStroke? get currentStroke => _currentStroke;
  bool get isEmpty => _strokes.isEmpty && _currentStroke == null;
  bool get isNotEmpty => !isEmpty;

  void startStroke(Offset point) {
    _currentStroke = SignatureStroke(
      points: [point],
      color: strokeColor,
      strokeWidth: strokeWidth,
    );
    notifyListeners();
  }

  void updateStroke(Offset point) {
    if (_currentStroke != null) {
      _currentStroke!.points.add(point);
      notifyListeners();
    }
  }

  void endStroke() {
    if (_currentStroke != null && _currentStroke!.points.isNotEmpty) {
      _strokes.add(_currentStroke!);
      _currentStroke = null;
      notifyListeners();
    }
  }

  void undo() {
    if (_strokes.isNotEmpty) {
      _strokes.removeLast();
      notifyListeners();
    }
  }

  void clear() {
    _strokes.clear();
    _currentStroke = null;
    notifyListeners();
  }

  /// Exports the canvas drawing as transparent PNG bytes.
  Future<Uint8List?> toPngBytes({int width = 700, int height = 280}) async {
    if (isEmpty) return null;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    );

    // Calculate bounding box to scale or draw cleanly
    final painter = SignaturePainter(
      strokes: _strokes,
      currentStroke: null,
      drawBaseline: false,
    );
    painter.paint(canvas, Size(width.toDouble(), height.toDouble()));

    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }
}

/// Interactive signature pad widget with drawing canvas.
class SignaturePadWidget extends StatefulWidget {
  final SignatureController controller;
  final double height;
  final Color backgroundColor;
  final String? placeholder;

  const SignaturePadWidget({
    super.key,
    required this.controller,
    this.height = 200,
    this.backgroundColor = Colors.white,
    this.placeholder,
  });

  @override
  State<SignaturePadWidget> createState() => _SignaturePadWidgetState();
}

class _SignaturePadWidgetState extends State<SignaturePadWidget> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChange);
    super.dispose();
  }

  void _onControllerChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (widget.controller.isEmpty && widget.placeholder != null)
            Center(
              child: Text(
                widget.placeholder!,
                style: TextStyle(
                  color: Colors.blueGrey.withValues(alpha: 0.4),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (details) {
                widget.controller.startStroke(details.localPosition);
              },
              onPanUpdate: (details) {
                widget.controller.updateStroke(details.localPosition);
              },
              onPanEnd: (_) {
                widget.controller.endStroke();
              },
              child: CustomPaint(
                painter: SignaturePainter(
                  strokes: widget.controller.strokes,
                  currentStroke: widget.controller.currentStroke,
                  drawBaseline: true,
                  baselineColor: Colors.blueGrey.withValues(alpha: 0.25),
                ),
                size: Size.infinite,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog / Modal for capturing digital signature on-screen with declaration text.
class SignaturePadDialog extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String? declaration;
  final String signerName;
  final String signerRole;
  final String confirmButtonText;

  const SignaturePadDialog({
    super.key,
    required this.title,
    this.subtitle,
    this.declaration,
    required this.signerName,
    required this.signerRole,
    this.confirmButtonText = 'Confirm & Sign',
  });

  static Future<Uint8List?> show(
    BuildContext context, {
    required String title,
    String? subtitle,
    String? declaration,
    required String signerName,
    required String signerRole,
    String confirmButtonText = 'Confirm & Sign',
  }) {
    return showModalBottomSheet<Uint8List>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SignaturePadDialog(
        title: title,
        subtitle: subtitle,
        declaration: declaration,
        signerName: signerName,
        signerRole: signerRole,
        confirmButtonText: confirmButtonText,
      ),
    );
  }

  @override
  State<SignaturePadDialog> createState() => _SignaturePadDialogState();
}

class _SignaturePadDialogState extends State<SignaturePadDialog> {
  late final SignatureController _controller;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      strokeColor: const Color(0xFF0F172A),
      strokeWidth: 3.2,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_controller.isEmpty) {
      await AppHaptics.heavy();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a signature before confirming')),
      );
      return;
    }

    setState(() => _exporting = true);
    await AppHaptics.medium();

    try {
      final bytes = await _controller.toPngBytes(width: 800, height: 320);
      if (mounted) {
        Navigator.pop(context, bytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating signature: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 16,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Header Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.draw_rounded, color: AppTheme.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle!,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Signer Tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.person_pin_rounded,
                      size: 18, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${widget.signerName} • ${widget.signerRole}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Declaration Text
            if (widget.declaration != null)
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  widget.declaration!,
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    height: 1.35,
                    color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
                  ),
                ),
              ),

            // Canvas
            SignaturePadWidget(
              controller: _controller,
              height: 200,
              backgroundColor: isDark ? const Color(0xFFF8FAFC) : const Color(0xFFF8FAFC),
              placeholder: 'Sign using finger or stylus above the line...',
            ),
            const SizedBox(height: 10),

            // Controls (Clear, Undo)
            Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 13,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Vector-smoothed',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {
                    AppHaptics.light();
                    _controller.undo();
                  },
                  icon: const Icon(Icons.undo_rounded, size: 15),
                  label: const Text('Undo', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: isDark ? Colors.white70 : Colors.black87,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 6),
                TextButton.icon(
                  onPressed: () {
                    AppHaptics.light();
                    _controller.clear();
                  },
                  icon: const Icon(Icons.delete_sweep_rounded, size: 15),
                  label: const Text('Clear', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.danger,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Confirm Button
            ElevatedButton(
              onPressed: _exporting ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _exporting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_rounded, size: 18),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            widget.confirmButtonText,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
