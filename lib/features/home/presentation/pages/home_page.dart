import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manara/core/constants/app_constants.dart';
import 'package:manara/core/router/app_routes.dart';
import 'package:manara/core/theme/theme.dart';
import 'package:manara/core/widgets/widgets.dart';

/// Placeholder until the real home screen is built from Figma.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(AppConstants.appName),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'القرآن الكريم',
              onPressed: () => context.push(AppRoutes.quran),
            ),
          ],
        ),
      ),
    );
  }
}
