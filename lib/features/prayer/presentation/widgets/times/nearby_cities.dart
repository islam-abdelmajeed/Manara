import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:manara/core/router/app_routes.dart';
import 'package:manara/core/theme/theme.dart';
import 'package:manara/features/prayer/domain/entities/prayer_location.dart';
import 'package:manara/features/prayer/domain/usecases/city_usecases.dart';
import 'package:manara/features/prayer/presentation/cubit/nearby_cities_cubit.dart';
import 'package:manara/features/prayer/presentation/cubit/prayer_times_cubit.dart';
import 'package:manara/features/prayer/presentation/utils/prayer_format.dart';
import 'package:manara/features/prayer/presentation/widgets/prayer_layout.dart';

/// "مدن قريبة": the nearest bundled cities; tapping one switches to it.
class NearbyCities extends StatelessWidget {
  const NearbyCities({super.key});

  @override
  Widget build(BuildContext context) {
    final location = context.select<PrayerTimesCubit, PrayerLocation>(
      (c) => c.state.location,
    );
    final nearby = context.watch<NearbyCitiesCubit>().state;
    final cities = nearby.from == location
        ? nearby.cities
        : const <CityDistance>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PrayerSectionTitle('مدن قريبة', large: false),
        const SizedBox(height: 31),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            for (final c in cities)
              _CityChip(
                name: c.city.name,
                distance: PrayerFormat.km(c.distanceKm),
                onTap: () =>
                    context.read<PrayerTimesCubit>().changeLocation(c.city),
              ),
          ],
        ),
        const SizedBox(height: 21),
        Wrap(
          spacing: 11,
          runSpacing: AppSpacing.xs,
          children: [
            _LinkButton(
              label: 'جميع المدن',
              onTap: () => context.go(AppRoutes.prayerCities()),
            ),
            _LinkButton(
              label: 'مدن ${location.country}',
              trailing: Icons.arrow_forward,
              onTap: () => context.go(
                AppRoutes.prayerCities(countryCode: location.countryCode),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CityChip extends StatelessWidget {
  const _CityChip({
    required this.name,
    required this.distance,
    required this.onTap,
  });

  final String name;
  final String distance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$name، $distance',
      excludeSemantics: true,
      child: Material(
        color: AppColors.beige500,
        borderRadius: AppRadius.mdAll,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: AppTypography.bodyLargeRegular.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    distance,
                    textDirection: TextDirection.ltr,
                    style: AppTypography.smallRegular.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LinkButton extends StatelessWidget {
  const _LinkButton({required this.label, required this.onTap, this.trailing});

  final String label;
  final VoidCallback onTap;
  final IconData? trailing;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: Material(
        color: AppColors.beige500,
        borderRadius: AppRadius.mdAll,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 100),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: AppTypography.captionMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (trailing case final icon?) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Icon(icon, size: 16, color: AppColors.textPrimary),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
