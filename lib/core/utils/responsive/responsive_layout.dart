import 'package:flutter/widgets.dart';
import 'package:manara/core/utils/responsive/breakpoints.dart';

/// Picks a builder by available width. [tablet] and [desktop] fall back
/// to the next smaller layout when not provided.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    required this.mobile,
    this.tablet,
    this.desktop,
    super.key,
  });

  final WidgetBuilder mobile;
  final WidgetBuilder? tablet;
  final WidgetBuilder? desktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return switch (deviceTypeForWidth(constraints.maxWidth)) {
          DeviceType.desktop => (desktop ?? tablet ?? mobile)(context),
          DeviceType.tablet => (tablet ?? mobile)(context),
          DeviceType.mobile => mobile(context),
        };
      },
    );
  }
}

/// Centers content and caps its width on wide screens.
class MaxWidthBox extends StatelessWidget {
  const MaxWidthBox({
    required this.child,
    this.maxWidth = Breakpoints.maxContentWidth,
    super.key,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
