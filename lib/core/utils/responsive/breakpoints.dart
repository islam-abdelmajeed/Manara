/// Width breakpoints (logical pixels) for adaptive layouts.
abstract final class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 1024;

  /// Max content width on large screens so mobile-first layouts don't stretch.
  static const double maxContentWidth = 1200;
}

enum DeviceType { mobile, tablet, desktop }

DeviceType deviceTypeForWidth(double width) {
  if (width < Breakpoints.mobile) return DeviceType.mobile;
  if (width < Breakpoints.tablet) return DeviceType.tablet;
  return DeviceType.desktop;
}
