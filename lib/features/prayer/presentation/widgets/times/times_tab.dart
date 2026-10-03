import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manara/core/theme/theme.dart';
import 'package:manara/features/prayer/presentation/cubit/prayer_times_cubit.dart';
import 'package:manara/features/prayer/presentation/utils/prayer_format.dart';
import 'package:manara/features/prayer/presentation/widgets/now_builder.dart';
import 'package:manara/features/prayer/presentation/widgets/prayer_layout.dart';
import 'package:manara/features/prayer/presentation/widgets/times/info_cards.dart';
import 'package:manara/features/prayer/presentation/widgets/times/nearby_cities.dart';
import 'package:manara/features/prayer/presentation/widgets/times/qibla_section.dart';
import 'package:manara/features/prayer/presentation/widgets/times/today_panel.dart';

/// "المواقيت و القبلة" (Figma "الصلاة - مواقيت و قبلة").
class TimesTab extends StatefulWidget {
  const TimesTab({required this.clock, this.showQibla = false, super.key});

  final DateTime Function() clock;
  final bool showQibla;

  @override
  State<TimesTab> createState() => _TimesTabState();
}

class _TimesTabState extends State<TimesTab> {
  final _qibla = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.showQibla) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final target = _qibla.currentContext;
        if (target != null && target.mounted) {
          Scrollable.ensureVisible(target);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final compact = PrayerLayout.isCompact(context);
    double gap(double design) => compact ? design * 0.45 : design;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PrayerSectionTitle(
          'مواقيت الصلاة',
          description:
              'احسب مواقيت الصلاة لموقعك بدقّة، مع اختيار طريقة الحساب '
              'والمذهب وضبط الدقائق. واتجاه القبلة والمسافة إلى الكعبة.',
        ),
        SizedBox(height: gap(81)),
        NowBuilder(
          clock: widget.clock,
          builder: (context, now) => TodayPanel(now: now),
        ),
        _OfflineNote(now: widget.clock()),
        SizedBox(height: gap(34)),
        const InfoCards(),
        SizedBox(height: gap(50)),
        const NearbyCities(),
        SizedBox(height: gap(47)),
        QiblaSection(key: _qibla),
      ],
    );
  }
}

/// Shown when the network failed and the times came from the device.
class _OfflineNote extends StatelessWidget {
  const _OfflineNote({required this.now});

  final DateTime now;

  static const Duration staleAfter = Duration(hours: 24);

  @override
  Widget build(BuildContext context) {
    final fetchedAt = context.select<PrayerTimesCubit, DateTime?>(
      (c) => c.state.times?.fetchedAt,
    );
    if (fetchedAt == null || now.difference(fetchedAt) < staleAfter) {
      return const SizedBox.shrink();
    }
    final local = fetchedAt.toLocal();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Text(
        'تعذّر التحديث؛ هذه المواقيت محفوظة على جهازك منذ '
        '${local.day} ${PrayerFormat.gregorianMonths[local.month - 1]}.',
        style: AppTypography.captionRegular.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
