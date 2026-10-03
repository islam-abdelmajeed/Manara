import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manara/core/di/injection.dart';
import 'package:manara/core/theme/theme.dart';
import 'package:manara/core/widgets/widgets.dart';
import 'package:manara/features/prayer/presentation/cubit/city_search_cubit.dart';
import 'package:manara/features/prayer/presentation/cubit/nearby_cities_cubit.dart';
import 'package:manara/features/prayer/presentation/cubit/prayer_month_cubit.dart';
import 'package:manara/features/prayer/presentation/cubit/prayer_times_cubit.dart';
import 'package:manara/features/prayer/presentation/widgets/prayer_header.dart';
import 'package:manara/features/prayer/presentation/widgets/alerts/alerts_tab.dart';
import 'package:manara/features/prayer/presentation/widgets/monthly/monthly_tab.dart';
import 'package:manara/features/prayer/presentation/widgets/prayer_layout.dart';
import 'package:manara/features/prayer/presentation/widgets/settings/settings_tab.dart';
import 'package:manara/features/prayer/presentation/widgets/times/times_tab.dart';

/// The prayer section. Each tab is its own route; the times come from the
/// app-wide [PrayerTimesCubit].
class PrayerPage extends StatelessWidget {
  const PrayerPage({
    required this.tab,
    this.showQibla = false,
    this.cities,
    super.key,
  });

  final PrayerTab tab;

  /// Scrolls to the qibla part of the times tab.
  final bool showQibla;

  /// Settings only: opens the city list, `all` or a country code (`EG`).
  final String? cities;

  CitySearchCubit _citySearch() {
    final cubit = getIt<CitySearchCubit>();
    final cities = this.cities;
    if (cities != null) {
      cubit.browse(countryCode: cities == 'all' ? null : cities.toUpperCase());
    }
    return cubit;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              getIt<NearbyCitiesCubit>()
                ..load(context.read<PrayerTimesCubit>().state.location),
        ),
        BlocProvider(create: (_) => getIt<PrayerMonthCubit>()),
        BlocProvider(create: (_) => _citySearch()),
      ],
      child: PrayerView(tab: tab, showQibla: showQibla),
    );
  }
}

/// Expects [PrayerTimesCubit], [NearbyCitiesCubit], [PrayerMonthCubit] and
/// [CitySearchCubit] above it.
class PrayerView extends StatelessWidget {
  const PrayerView({
    required this.tab,
    this.showQibla = false,
    this.clock = DateTime.now,
    super.key,
  });

  final PrayerTab tab;
  final bool showQibla;

  /// Injectable for tests.
  final DateTime Function() clock;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final padding = PrayerLayout.sidePadding(width);
    final compact = PrayerLayout.isCompact(context);

    return BlocListener<PrayerTimesCubit, PrayerTimesState>(
      listenWhen: (a, b) => a.location != b.location,
      listener: (context, state) =>
          context.read<NearbyCitiesCubit>().load(state.location),
      child: AppScaffold(
        active: NavItem.prayer,
        body: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            padding,
            compact ? AppSpacing.lg : 113,
            padding,
            compact ? AppSpacing.xxl : 97,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: PrayerLayout.contentWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PrayerHeader(tab: tab),
                  SizedBox(height: compact ? AppSpacing.xl : 58),
                  switch (tab) {
                    PrayerTab.times => TimesTab(
                      clock: clock,
                      showQibla: showQibla,
                    ),
                    PrayerTab.monthly => _MonthlyHost(clock: clock),
                    PrayerTab.settings => const SettingsTab(),
                    PrayerTab.alerts => const AlertsTab(),
                  },
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Keeps the monthly table on the location's current month at first, and
/// on the shown month for a new city or new settings.
class _MonthlyHost extends StatefulWidget {
  const _MonthlyHost({required this.clock});

  final DateTime Function() clock;

  @override
  State<_MonthlyHost> createState() => _MonthlyHostState();
}

class _MonthlyHostState extends State<_MonthlyHost> {
  @override
  void initState() {
    super.initState();
    final prayer = context.read<PrayerTimesCubit>().state;
    final month = context.read<PrayerMonthCubit>().state;
    // The location's date once today's times are known; UTC before that.
    final today = prayer.times?.today.date ?? widget.clock().toUtc();
    context.read<PrayerMonthCubit>().show(
      year: month.month == 0 ? today.year : month.year,
      month: month.month == 0 ? today.month : month.month,
      location: prayer.location,
      settings: prayer.settings,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PrayerTimesCubit, PrayerTimesState>(
      listenWhen: (a, b) =>
          a.location != b.location || a.settings != b.settings,
      listener: (context, prayer) {
        final month = context.read<PrayerMonthCubit>().state;
        context.read<PrayerMonthCubit>().show(
          year: month.year,
          month: month.month,
          location: prayer.location,
          settings: prayer.settings,
        );
      },
      child: MonthlyTab(clock: widget.clock),
    );
  }
}
