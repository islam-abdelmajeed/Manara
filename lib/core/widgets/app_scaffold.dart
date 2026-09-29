import 'package:flutter/material.dart';
import 'package:manara/core/theme/theme.dart';
import 'package:manara/core/widgets/app_nav_bar.dart';

/// Page shell shared by top-level screens: the navigation bar, its drawer
/// on compact widths, and the page background.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.active,
    required this.body,
    this.backgroundColor = AppColors.readerBackground,
    super.key,
  });

  final NavItem active;
  final Widget body;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppNavBar(active: active),
      endDrawer: AppNavBar.isCompact(context)
          ? AppNavDrawer(active: active)
          : null,
      body: body,
    );
  }
}
