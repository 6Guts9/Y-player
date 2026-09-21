import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/themes/theme.dart';
import '../../../../core/themes/theme_provider.dart';

class ThemedBar extends ConsumerStatefulWidget {
  final double value;
  final double max;
  final ValueChanged<double>? onChanged;
  final bool isPlaying;

  const ThemedBar({
    super.key,
    required this.value,
    required this.max,
    this.onChanged,
    this.isPlaying = false,
  });

  @override
  ConsumerState<ThemedBar> createState() => _ThemedBarState();
}

class _ThemedBarState extends ConsumerState<ThemedBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(ThemedBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat();
      } else {
        _controller.stop();
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
    final preset = ref.watch(themeProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        if (widget.onChanged != null) {
          final box = context.findRenderObject() as RenderBox;
          final local = box.globalToLocal(details.globalPosition);
          final percent = (local.dx / box.size.width).clamp(0.0, 1.0);
          widget.onChanged!(percent * widget.max);
        }
      },
      onTapDown: (details) {
        if (widget.onChanged != null) {
          final box = context.findRenderObject() as RenderBox;
          final local = box.globalToLocal(details.globalPosition);
          final percent = (local.dx / box.size.width).clamp(0.0, 1.0);
          widget.onChanged!(percent * widget.max);
        }
      },
      child: Container(
        height: 40,
        width: double.infinity,
        color: Colors.transparent,

        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _BarPainter(
                progress: widget.value / widget.max,
                animationValue: _controller.value,
                preset: preset,
                colorScheme: colorScheme,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  final double progress;
  final double animationValue;
  final AppThemePreset preset;
  final ColorScheme colorScheme;

  _BarPainter({
    required this.progress,
    required this.animationValue,
    required this.preset,
    required this.colorScheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.0;

    final centerY = size.height / 2;
    final barWidth = size.width;

    // Draw background bar
    paint.color = colorScheme.surfaceContainerHighest.withValues(alpha: 0.4);
    canvas.drawLine(Offset(0, centerY), Offset(barWidth, centerY), paint);


    paint.color = colorScheme.primary;

    switch (preset) {
      case AppThemePreset.minimalist:
        _paintMinimalist(canvas, size, paint);
        break;
      case AppThemePreset.pixelArt:
        _paintPixelArt(canvas, size, paint);
        break;
      case AppThemePreset.artDeco:
        _paintArtDeco(canvas, size, paint);
        break;
      case AppThemePreset.aurora:
        _paintAurora(canvas, size, paint);
        break;
      case AppThemePreset.ascii:
        _paintAscii(canvas, size, paint);
        break;
      case AppThemePreset.cybersigilism:
        _paintCybersigilism(canvas, size, paint);
        break;
    }

    // Draw knob
    final knobX = progress * barWidth;
    final knobPaint = Paint()..color = colorScheme.primary;
    canvas.drawCircle(Offset(knobX, centerY), 6, knobPaint);
  }

  void _paintMinimalist(Canvas canvas, Size size, Paint paint) {
    final centerY = size.height / 2;
    final activeWidth = size.width * progress;

    void drawLayer(double phase, double amp, double freq, double alpha) {
      final path = Path();
      path.moveTo(0, centerY);
      for (double i = 0; i <= activeWidth; i += 1.5) {
        // High-frequency "jitter" mixed with low-frequency "lows" for a spiky look
        final baseWave = math.sin((i / freq) + (animationValue * 4 * math.pi) + phase);
        final noise = math.sin((i / (freq * 0.2)) + (animationValue * 10 * math.pi)) * 0.4;
        final wave = (baseWave + noise) * amp;
        
        path.lineTo(i, centerY - wave);
      }
      path.lineTo(activeWidth, centerY);
      canvas.drawPath(
        path,
        Paint()
          ..color = colorScheme.primary.withValues(alpha: alpha)
          ..style = PaintingStyle.fill,
      );
    }

    // Deeper amp for "lows" and smaller freq divisors for more "spikes"
    drawLayer(0, 15, 20, 0.15);
    drawLayer(math.pi / 1.5, 11, 14, 0.12);
    drawLayer(math.pi / 3, 8, 9, 0.1);

    // Main solid line on top
    canvas.drawLine(Offset(0, centerY), Offset(activeWidth, centerY), paint);
  }

  void _paintPixelArt(Canvas canvas, Size size, Paint paint) {
    final centerY = size.height / 2;
    final barWidth = size.width;
    final activeWidth = barWidth * progress;

    // 1. Draw "CRT Matrix" (Grainy scanlines)
    final scanlinePaint = Paint()
      ..color = colorScheme.primary.withValues(alpha: 0.05)
      ..strokeWidth = 1.0;
    for (double i = 0; i < size.height; i += 2) {
      canvas.drawLine(Offset(0, i), Offset(barWidth, i), scanlinePaint);
    }

    // 2. Draw Pixel Background Bar
    final bgPaint = Paint()
      ..color = colorScheme.primary.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, centerY - 6, barWidth, 12), bgPaint);

    // 3. Draw "Progress Fill" (Stepped/Pixelated)
    final fillPaint = Paint()
      ..color = colorScheme.primary.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    const pixelStep = 4.0;
    for (double x = 0; x < activeWidth; x += pixelStep) {
      canvas.drawRect(Rect.fromLTWH(x, centerY - 6, pixelStep - 1, 12), fillPaint);
    }

    // 4. Draw Oscilloscope Line (Pixelated)
    final linePaint = Paint()
      ..color = colorScheme.primary
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = colorScheme.primary.withValues(alpha: 0.4)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final path = Path();
    path.moveTo(0, centerY);

    // High frequency "vibrating" pixel wave
    final flicker = (math.sin(animationValue * 120) * 0.05) + 0.95;
    
    for (double x = 0; x < activeWidth; x += pixelStep) {
      // Create a stepped/jagged wave
      final wave = math.sin((x * 0.15) + (animationValue * 15)) * 14;
      final noise = math.sin(x * 1.2 + animationValue * 80) * 3;
      final y = centerY - (wave + noise) * flicker;
      
      // Draw vertical "pixel connectors"
      path.lineTo(x, y);
      path.lineTo(x + pixelStep, y);
    }

    // Draw the glowing line
    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, linePaint);

    // 5. Vertical "Scan" bar moving across the whole bar
    final scanX = (animationValue * barWidth * 1.5) % (barWidth * 2);
    if (scanX < barWidth) {
      canvas.drawLine(
        Offset(scanX, 0),
        Offset(scanX, size.height),
        Paint()
          ..color = colorScheme.primary.withValues(alpha: 0.15)
          ..strokeWidth = 12
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
  }

  void _paintArtDeco(Canvas canvas, Size size, Paint paint) {
    final centerY = size.height / 2;
    final activeWidth = size.width * progress;

    canvas.drawLine(Offset(0, centerY), Offset(activeWidth, centerY), paint);

    final linePaint = Paint()
      ..color = colorScheme.primary.withValues(alpha: 0.5)
      ..strokeWidth = 1.0;

    for (double i = 0; i <= activeWidth; i += 15) {
      final h = 10 + math.cos((i / 50) + (animationValue * 2 * math.pi)) * 8;
      canvas.drawLine(Offset(i, centerY - h), Offset(i + 10, centerY + h), linePaint);
    }
  }

  void _paintAurora(Canvas canvas, Size size, Paint paint) {
    final centerY = size.height / 2;
    final activeWidth = size.width * progress;

    final gradient = LinearGradient(
      colors: [colorScheme.primary, colorScheme.secondary, colorScheme.tertiary],
      stops: [
        (animationValue - 0.2).clamp(0.0, 1.0),
        animationValue,
        (animationValue + 0.2).clamp(0.0, 1.0),
      ],
    ).createShader(Rect.fromLTWH(0, 0, activeWidth, size.height));

    paint.shader = gradient;
    paint.strokeWidth = 8.0;
    canvas.drawLine(Offset(0, centerY), Offset(activeWidth, centerY), paint);
  }

  void _paintAscii(Canvas canvas, Size size, Paint paint) {
    final centerY = size.height / 2;
    final activeWidth = size.width * progress;

    // Drawing small dots/dashes to simulate ASCII
    for (double i = 0; i <= activeWidth; i += 10) {
      final char = (i + (animationValue * 50)).toInt() % 3 == 0 ? '-' : '=';
      final textPainter = TextPainter(
        text: TextSpan(
          text: char,
          style: TextStyle(color: colorScheme.primary, fontSize: 14, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(i, centerY - 10));
    }
  }

  void _paintCybersigilism(Canvas canvas, Size size, Paint paint) {
    final centerY = size.height / 2;
    final activeWidth = size.width * progress;

    // 1. Draw "Old Computer Grid" (more dense)
    final gridPaint = Paint()
      ..color = colorScheme.primary.withValues(alpha: 0.1)
      ..strokeWidth = 0.5;
    
    for (double x = 0; x <= activeWidth; x += 10) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += 8) {
      canvas.drawLine(Offset(0, y), Offset(activeWidth, y), gridPaint);
    }

    // 2. Draw "Ghosting" effect (flicker)
    final flicker = (math.sin(animationValue * 100) * 0.1) + 0.9;

    // 3. Draw Oscilloscope Wave (matching the image)
    final path = Path();
    path.moveTo(0, centerY);

    for (double i = 0; i <= activeWidth; i += 1.0) {
      final x = i;
      // High frequency + Low frequency mix for that "scanning" look
      final wave1 = math.sin((x * 0.1) + (animationValue * 20)) * 12;
      final wave2 = math.cos((x * 0.05) - (animationValue * 12)) * 6;
      final jitter = (math.sin(x * 3.0 + animationValue * 100)) * 2.0;
      
      path.lineTo(x, centerY + (wave1 + wave2 + jitter) * flicker);
    }

    // Outer glow (more intense)
    canvas.drawPath(
      path,
      Paint()
        ..color = colorScheme.primary.withValues(alpha: 0.4 * flicker)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // Main sharp glowing line
    canvas.drawPath(
      path,
      Paint()
        ..color = colorScheme.primary.withValues(alpha: 0.9 * flicker)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // 4. Draw horizontal "Scanline" passing through
    final scanY = (animationValue * size.height * 2) % (size.height * 3);
    if (scanY < size.height) {
      canvas.drawLine(
        Offset(0, scanY),
        Offset(activeWidth, scanY),
        Paint()
          ..color = colorScheme.primary.withValues(alpha: 0.2)
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.animationValue != animationValue;
}
