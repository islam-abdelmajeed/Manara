import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manara/core/di/injection.dart';
import 'package:manara/core/widgets/widgets.dart';
import 'package:manara/features/home/presentation/cubit/home_cubit.dart';
import 'package:manara/features/home/presentation/widgets/daily_adhkar_card.dart';
import 'package:manara/features/home/presentation/widgets/hadith_of_day_card.dart';
import 'package:manara/features/home/presentation/widgets/hero_section.dart';
import 'package:manara/features/home/presentation/widgets/home_layout.dart';
import 'package:manara/features/home/presentation/widgets/prayer_times_card.dart';
import 'package:manara/features/home/presentation/widgets/quick_access_section.dart';
import 'package:manara/features/home/presentation/widgets/reading_journey_card.dart';
import 'package:manara/features/home/presentation/widgets/treasures_section.dart';
import 'package:manara/features/prayer/presentation/cubit/prayer_times_cubit.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<HomeCubit>()..load()),
        BlocProvider(create: (_) => getIt<PrayerTimesCubit>()..load()),
      ],
      child: const HomeView(),
    );
  }
}

/// Home layout from Figma "Desktop - 1". Expects [HomeCubit] and
/// [PrayerTimesCubit] above it.
class HomeView extends StatelessWidget {
  const HomeView({this.clock = DateTime.now, super.key});

  /// Injectable for tests.
  final DateTime Function() clock;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final padding = HomeLayout.sidePadding(width);
    final wide = HomeLayout.isWide(width);
    final home = context.watch<HomeCubit>().state;

    // Vertical rhythm from Figma, tightened on small screens.
    final small = width < 700;
    double gap(double design) => small ? design * 0.45 : design;

    final hadith = HadithOfDayCard(hadith: home.hadith);
    final prayer = PrayerTimesCard(clock: clock);
    final adhkar = DailyAdhkarCard(period: AdhkarPeriod.of(clock()));
    final journey = ReadingJourneyCard(
      juz: home.progress.currentJuz,
      streak: home.streak,
    );

    return AppScaffold(
      active: NavItem.home,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const HeroSection(),
            SizedBox(height: gap(74)),
            _Padded(padding: padding, child: const QuickAccessSection()),
            SizedBox(height: gap(74)),
            _Padded(
              padding: padding,
              child: wide
                  ? _Pair(
                      start: hadith,
                      startDesign: HadithOfDayCard.designSize,
                      end: prayer,
                      endDesign: PrayerTimesCard.designSize,
                      designGap: 86,
                    )
                  : _Stack(children: [hadith, prayer]),
            ),
            SizedBox(height: gap(70)),
            _Padded(
              padding: padding,
              child: wide
                  ? _Pair(
                      start: adhkar,
                      startDesign: DailyAdhkarCard.designSize,
                      end: journey,
                      endDesign: ReadingJourneyCard.designSize,
                      designGap: 84,
                    )
                  : _Stack(children: [adhkar, journey]),
            ),
            SizedBox(height: gap(121)),
            TreasuresSection(sidePadding: padding),
            SizedBox(height: gap(112)),
            const AppFooter(),
          ],
        ),
      ),
    );
  }
}

class _Padded extends StatelessWidget {
  const _Padded({required this.padding, required this.child});

  final double padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: HomeLayout.contentWidth),
          child: child,
        ),
      ),
    );
  }
}

/// Two design cards side by side, sized in the Figma width ratio so both
/// scale by the same factor and keep their shared baseline.
class _Pair extends StatelessWidget {
  const _Pair({
    required this.start,
    required this.startDesign,
    required this.end,
    required this.endDesign,
    required this.designGap,
  });

  final Widget start;
  final Size startDesign;
  final Widget end;
  final Size endDesign;
  final double designGap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final designTotal = startDesign.width + designGap + endDesign.width;
        final scale = (constraints.maxWidth / designTotal).clamp(0.0, 1.0);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(width: startDesign.width * scale, child: start),
            SizedBox(width: endDesign.width * scale, child: end),
          ],
        );
      },
    );
  }
}

/// Cards stacked on narrow screens, each at most its design width.
class _Stack extends StatelessWidget {
  const _Stack({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: 32),
          Center(child: children[i]),
        ],
      ],
    );
  }
}
