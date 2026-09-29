import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Lays [child] out at the exact Figma frame [size] and scales it down
/// uniformly when less width is available, so absolute positions taken from
/// the design stay correct at every width.
class DesignBox extends StatelessWidget {
  const DesignBox({required this.size, required this.child, super.key});

  final Size size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = constraints.hasBoundedWidth
            ? math.min(1.0, constraints.maxWidth / size.width)
            : 1.0;
        return SizedBox(
          width: size.width * scale,
          height: size.height * scale,
          child: FittedBox(
            fit: BoxFit.fill,
            child: SizedBox.fromSize(size: size, child: child),
          ),
        );
      },
    );
  }
}
