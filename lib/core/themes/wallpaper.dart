import 'package:flutter/material.dart';
import 'theme.dart';

class AppWallpaper {
  AppWallpaper._();

  static Widget? wallpaperFor(AppThemePreset preset) {
    switch (preset) {
      case AppThemePreset.aurora:
        return const _AuroraWallpaper();
      case AppThemePreset.minimalist:
        return const _minimalistWallpaper();
      case AppThemePreset.pixelArt:
        return const _pixelArtWallpaper();
      case AppThemePreset.artDeco:
        return const _artDecoWallpaper();
      case AppThemePreset.ascii:
        return const _asciiWallpaper();
      case AppThemePreset.cybersigilism:
        return const _cybersigilismWallpaper();

    }
  }
}
class _minimalistWallpaper extends StatelessWidget {
  const _minimalistWallpaper();
  @override
  Widget build(BuildContext context) {
    return Container();

  }

}
class _pixelArtWallpaper extends StatelessWidget {
  const _pixelArtWallpaper();
  @override
  Widget build(BuildContext context) {
    return Container(

      color: const Color(0xFF001A12),
      child: CustomPaint(

        painter: _PixelGridPainter(lineColor: const Color(0xFF00E5A0).withOpacity(0.12)),
        size: Size.infinite,
      ),
    );
  }
}

class _PixelGridPainter extends CustomPainter {
  final Color lineColor;
  const _PixelGridPainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    const cellSize = 24.0;
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += cellSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += cellSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PixelGridPainter oldDelegate) => false;
}

class _artDecoWallpaper extends StatelessWidget {
  const _artDecoWallpaper();
  @override
  Widget build(BuildContext context) {
    return Container();
  }

}
class _asciiWallpaper extends StatelessWidget {
  const _asciiWallpaper();
  @override
  Widget build(BuildContext context) {
    return Container();

  }

}
class _cybersigilismWallpaper extends StatelessWidget {
  const _cybersigilismWallpaper();
  @override
  Widget build(BuildContext context) {
    return Container();

  }

}
class _AuroraWallpaper extends StatelessWidget {
  const _AuroraWallpaper();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.3, -0.6),
          radius: 1.4,
          colors: [Color(0xFF2EE6A8), Color(0xFF8A5CF6), Color(0xFF0B0E1A)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}