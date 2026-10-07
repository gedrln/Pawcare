import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Keeps translucent surfaces while avoiding BackdropFilter's WebGL shader
/// path in Flutter web browsers.
class PlatformBackdropBlur extends StatelessWidget {
  final Widget child;
  final double sigmaX;
  final double sigmaY;

  const PlatformBackdropBlur({
    super.key,
    required this.child,
    this.sigmaX = 18,
    this.sigmaY = 18,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return child;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY),
      child: child,
    );
  }
}
