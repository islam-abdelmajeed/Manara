import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manara/core/platform/browser_actions.dart';
import 'package:manara/core/theme/theme.dart';
import 'package:manara/core/widgets/widgets.dart';
import 'package:manara/features/prayer/domain/entities/prayer_alerts.dart';
import 'package:manara/features/prayer/domain/entities/prayer_times.dart';
import 'package:manara/features/prayer/presentation/cubit/prayer_alerts_cubit.dart';
import 'package:manara/features/prayer/presentation/utils/prayer_format.dart';
import 'package:manara/features/prayer/presentation/widgets/prayer_form.dart';
import 'package:manara/features/prayer/presentation/widgets/prayer_layout.dart';

/// "التنبيهات" (Figma "الصلاة -التنبيهات"). On Android and iOS alerts are
/// scheduled with the system; elsewhere they fire while the app (or the
/// browser tab) is open. Tones and adhan voices are not available yet.
class AlertsTab extends StatelessWidget {
  const AlertsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final compact = PrayerLayout.isCompact(context);
    final schedulesAhead = context.select<PrayerAlertsCubit, bool>(
      (c) => c.state.schedulesAhead,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PrayerSectionTitle(
          'تنبيهات الصلاة',
          description: schedulesAhead
              ? 'تنبيهات المواقيت على جهازك، وتصلك حتى والتطبيق مغلق.'
              : BrowserActions.supported
              ? 'تنبيهات المواقيت داخل متصفحك، وتعمل ما دام هذا التبويب مفتوحًا.'
              : 'تنبيهات المواقيت داخل التطبيق، وتعمل ما دام التطبيق مفتوحًا.',
        ),
        const _PermissionNote(),
        SizedBox(height: compact ? AppSpacing.lg : 50),
        const _PrayersCard(),
        SizedBox(height: compact ? AppSpacing.lg : 38),
        const _ExtraCard(),
      ],
    );
  }
}

/// What happens to alerts given the notification permission (and, on
/// Android, whether exact alarms are allowed).
class _PermissionNote extends StatelessWidget {
  const _PermissionNote();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PrayerAlertsCubit>();
    final state = context.watch<PrayerAlertsCubit>().state;
    final late = state.schedulesAhead && state.canNotify && !state.exact;
    if (!state.settings.anyEnabled || (state.canNotify && !late)) {
      return const SizedBox.shrink();
    }
    final String text;
    VoidCallback? allow;
    if (late) {
      text =
          'اسمح للتطبيق بـ«المنبّهات والتذكيرات» من إعدادات الجهاز لتصل '
          'التنبيهات في وقتها بالضبط؛ وإلا فقد تتأخر بضع دقائق.';
      allow = cubit.requestExact;
    } else if (state.schedulesAhead) {
      text = switch (state.permission) {
        'default' => 'اسمح للتطبيق بالإشعارات لتصلك التنبيهات والتطبيق مغلق.',
        _ =>
          'الإشعارات مقفلة من إعدادات الجهاز؛ ستظهر التنبيهات داخل التطبيق '
              'ما دام مفتوحًا.',
      };
    } else {
      text = switch (state.permission) {
        'default' => 'اسمح للمتصفح بالإشعارات لتصلك التنبيهات خارج الصفحة.',
        'denied' =>
          'الإشعارات محجوبة في إعدادات المتصفح؛ ستظهر التنبيهات داخل الصفحة.',
        _ => 'ستظهر التنبيهات داخل التطبيق ما دام مفتوحًا.',
      };
    }
    if (!late && state.canAsk) allow = cubit.requestPermission;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.lightGold50,
          borderRadius: AppRadius.mdAll,
          border: Border.all(color: AppColors.lightGold200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              const AppIcon(
                AppIcons.infoCircle,
                size: 18,
                color: AppColors.lightGold600,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  text,
                  style: AppTypography.captionRegular.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (allow != null) ...[
                const SizedBox(width: AppSpacing.sm),
                TextButton(onPressed: allow, child: const Text('السماح')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PrayersCard extends StatelessWidget {
  const _PrayersCard();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PrayerAlertsCubit>();
    final settings = context.watch<PrayerAlertsCubit>().state.settings;
    return PrayerFormCard(
      title: 'الصلوات الخمس',
      subtitle:
          'لكل صلاة تنبيه ومهلة تنبيه مسبق. ولا يُجدول شيء عند الشروق؛ فهو '
          'نهاية وقت الفجر وليس صلاة.',
      children: [
        for (final prayer in Prayer.values.where((p) => p.isPrayer)) ...[
          _PrayerAlertRow(
            prayer: prayer,
            alert: settings.alertOf(prayer),
            onChanged: (alert) =>
                cubit.update(cubit.state.settings.withPrayer(prayer, alert)),
          ),
          if (prayer != Prayer.isha) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _PrayerAlertRow extends StatelessWidget {
  const _PrayerAlertRow({
    required this.prayer,
    required this.alert,
    required this.onChanged,
  });

  final Prayer prayer;
  final PrayerAlert alert;
  final ValueChanged<PrayerAlert> onChanged;

  @override
  Widget build(BuildContext context) {
    final compact = PrayerLayout.isCompact(context);
    final fields = <Widget>[
      PrayerSelectField<int>(
        label: 'التنبيه المسبق',
        value: alert.minutesBefore,
        options: PrayerAlert.beforeChoices,
        optionLabel: (m) =>
            m == 0 ? 'بدون تنبيه مسبق' : 'قبل ${PrayerFormat.minutes(m)}',
        enabled: alert.enabled,
        onChanged: (m) => onChanged(alert.copyWith(minutesBefore: m)),
      ),
      for (final label in ['النغمة', 'الأذان', 'صوت المؤذن'])
        PrayerSelectField<String>(
          label: label,
          value: 'قريبًا',
          options: const ['قريبًا'],
          optionLabel: (v) => v,
          enabled: false,
          onChanged: (_) {},
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SwitchRow(
          label: prayer.label,
          value: alert.enabled,
          onChanged: (v) => onChanged(alert.copyWith(enabled: v)),
        ),
        const SizedBox(height: AppSpacing.xs),
        if (compact)
          for (final (i, f) in fields.indexed) ...[
            if (i > 0) const SizedBox(height: AppSpacing.xs),
            f,
          ]
        else
          for (var i = 0; i < fields.length; i += 2) ...[
            if (i > 0) const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(child: fields[i]),
                const SizedBox(width: AppSpacing.xs),
                Expanded(child: fields[i + 1]),
              ],
            ),
          ],
      ],
    );
  }
}

class _ExtraCard extends StatelessWidget {
  const _ExtraCard();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PrayerAlertsCubit>();
    final settings = context.watch<PrayerAlertsCubit>().state.settings;
    return PrayerFormCard(
      title: 'تنبيهات إضافية',
      subtitle:
          'تنبيه السحور قبل أذان الفجر، وتنبيه الجمعة يوم الجمعة قبل '
          'صلاة الجمعة.',
      children: [
        // Figma groups the two in an inner outlined box.
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AppRadius.mdAll,
            border: Border.all(color: AppColors.green400),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xxs,
            ),
            child: Column(
              children: [
                _SwitchRow(
                  label: 'تنبيه السحور',
                  detail:
                      'قبل أذان الفجر بـ ${PrayerFormat.minutes(AlertSettings.suhoorMinutes)}',
                  value: settings.suhoor,
                  onChanged: (v) =>
                      cubit.update(cubit.state.settings.copyWith(suhoor: v)),
                ),
                const SizedBox(height: AppSpacing.xs),
                _SwitchRow(
                  label: 'تنبيه الجمعة',
                  detail:
                      'يوم الجمعة قبل أذان الظهر بـ '
                      '${PrayerFormat.minutes(AlertSettings.fridayMinutes)}',
                  value: settings.friday,
                  onChanged: (v) =>
                      cubit.update(cubit.state.settings.copyWith(friday: v)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.detail,
  });

  final String label;
  final String? detail;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final detail = this.detail;
    return MergeSemantics(
      child: InkWell(
        borderRadius: AppRadius.mdAll,
        onTap: () => onChanged(!value),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (detail != null)
                      Text(
                        detail,
                        style: AppTypography.labelRegular.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: AppColors.white50,
                activeTrackColor: AppColors.green500,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
