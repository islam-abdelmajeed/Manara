import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manara/core/theme/theme.dart';
import 'package:manara/core/widgets/widgets.dart';
import 'package:manara/features/prayer/domain/entities/prayer_location.dart';
import 'package:manara/features/prayer/domain/entities/prayer_method.dart';
import 'package:manara/features/prayer/domain/entities/prayer_settings.dart';
import 'package:manara/features/prayer/domain/entities/prayer_times.dart';
import 'package:manara/features/prayer/presentation/cubit/city_search_cubit.dart';
import 'package:manara/features/prayer/presentation/cubit/prayer_times_cubit.dart';
import 'package:manara/features/prayer/presentation/utils/prayer_labels.dart';
import 'package:manara/features/prayer/presentation/widgets/prayer_form.dart';
import 'package:manara/features/prayer/presentation/widgets/prayer_layout.dart';

/// "الإعدادات" (Figma "الصلاة- اعدادات"): the city, how times are
/// calculated, the Hijri offset and per-prayer minute adjustments. Changes
/// apply at once and are saved on the device. Expects [CitySearchCubit].
class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final compact = PrayerLayout.isCompact(context);
    final gap = compact ? AppSpacing.lg : 50.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PrayerSectionTitle(
          'إعدادات حساب المواقيت',
          description:
              'اختر طريقة الحساب ومذهب العصر وقاعدة خطوط العرض العالية، ثم '
              'اضبط الدقائق يدويًا. تُحفظ إعداداتك على هذا الجهاز وحده.',
        ),
        SizedBox(height: gap),
        const _LocationCard(),
        SizedBox(height: gap),
        const _CalculationCard(),
        SizedBox(height: gap),
        const PrayerSectionTitle(
          'الضبط الدقيق',
          description: 'اضبط الدقائق حتى توافق التقويم الذي تتبعه.',
        ),
        SizedBox(height: compact ? AppSpacing.md : 40),
        const _TuneCard(),
        SizedBox(height: gap),
        const _ResetCard(),
      ],
    );
  }
}

class _LocationCard extends StatefulWidget {
  const _LocationCard();

  @override
  State<_LocationCard> createState() => _LocationCardState();
}

class _LocationCardState extends State<_LocationCard> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pick(PrayerLocation city) async {
    _controller.clear();
    context.read<CitySearchCubit>().clear();
    showAppToast(context, 'تم اختيار ${city.name}');
    await context.read<PrayerTimesCubit>().changeLocation(city);
  }

  @override
  Widget build(BuildContext context) {
    final location = context.select<PrayerTimesCubit, PrayerLocation>(
      (c) => c.state.location,
    );
    final search = context.watch<CitySearchCubit>().state;

    return PrayerFormCard(
      title: 'الموقع',
      subtitle: 'المكان الذي تُحسب له مواقيت اليوم.',
      children: [
        _CurrentCity(location: location),
        const SizedBox(height: AppSpacing.md),
        const Divider(color: AppColors.beige500, height: 1),
        const SizedBox(height: AppSpacing.md),
        Text(
          'ابحث عن مدينة',
          style: AppTypography.captionBold.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        AppSearchField(
          hint: 'اكتب اسم المدينة… مثل: القاهرة أو Cairo',
          controller: _controller,
          fillColor: AppColors.cream100,
          onChanged: context.read<CitySearchCubit>().search,
        ),
        if (search.isOpen) ...[
          const SizedBox(height: AppSpacing.xs),
          _Results(
            results: search.results,
            selectedId: location.id,
            onPick: _pick,
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        Text(
          'بيانات المدن من GeoNames (CC BY 4.0).',
          style: AppTypography.smallRegular.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _CurrentCity extends StatelessWidget {
  const _CurrentCity({required this.location});

  final PrayerLocation location;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'المدينة الحالية: ${location.label}',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: AppRadius.mdAll,
          border: Border.all(color: AppColors.darkBrown200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.beige400,
                child: AppIcon(
                  AppIcons.markerPin,
                  size: 18,
                  color: AppColors.green700,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.label,
                      style: AppTypography.bodyBold.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'المنطقة الزمنية: ${location.timeZone}',
                      style: AppTypography.labelRegular.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({
    required this.results,
    required this.selectedId,
    required this.onPick,
  });

  final List<PrayerLocation> results;
  final int selectedId;
  final ValueChanged<PrayerLocation> onPick;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Text(
          'لا توجد مدينة بهذا الاسم في القائمة.',
          style: AppTypography.captionRegular.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.cream100,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.beige500),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 320),
        child: ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: results.length,
          separatorBuilder: (_, _) =>
              const Divider(height: 1, color: AppColors.beige400),
          itemBuilder: (context, i) {
            final city = results[i];
            final selected = city.id == selectedId;
            return ListTile(
              minTileHeight: 48,
              selected: selected,
              selectedColor: AppColors.primary,
              title: Text(
                city.name,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              subtitle: Text(
                city.country,
                style: AppTypography.labelRegular.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              trailing: selected
                  ? const Icon(Icons.check_rounded, color: AppColors.primary)
                  : null,
              onTap: selected ? null : () => onPick(city),
            );
          },
        ),
      ),
    );
  }
}

class _CalculationCard extends StatelessWidget {
  const _CalculationCard();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PrayerTimesCubit>();
    final state = context.watch<PrayerTimesCubit>().state;
    final settings = state.settings;
    final method = PrayerMethod.byId(settings.method) ?? PrayerMethod.egypt;
    final hijri = state.times?.today.hijri;

    return PrayerFormCard(
      title: 'الحساب',
      subtitle: 'الطريقة التي تُحسب بها مواقيتك، وكيفية قياس وقت العصر.',
      children: [
        PrayerSelectField<PrayerMethod>(
          label: 'طريقة الحساب',
          value: method,
          options: PrayerMethod.values,
          optionLabel: (m) => m.label,
          onChanged: (m) =>
              cubit.changeSettings(settings.copyWith(method: m.id)),
        ),
        const SizedBox(height: AppSpacing.sm),
        PrayerSelectField<AsrSchool>(
          label: 'مذهب العصر',
          value: settings.school,
          options: AsrSchool.values,
          optionLabel: (s) => s.label,
          optionDetail: (s) => s.detail,
          onChanged: (s) => cubit.changeSettings(settings.copyWith(school: s)),
        ),
        const SizedBox(height: AppSpacing.sm),
        PrayerSelectField<HighLatitudeRule>(
          label: 'خطوط العرض العالية',
          value: settings.highLatitudeRule,
          options: HighLatitudeRule.values,
          optionLabel: (r) => r.label,
          optionDetail: (r) => r.detail,
          onChanged: (r) =>
              cubit.changeSettings(settings.copyWith(highLatitudeRule: r)),
        ),
        const SizedBox(height: AppSpacing.md),
        PrayerStepper(
          key: ValueKey('hijri-${settings.hijriOffset}'),
          label: 'تعديل التاريخ الهجري',
          value: settings.hijriOffset,
          min: -PrayerSettings.maxHijriOffset,
          max: PrayerSettings.maxHijriOffset,
          valueLabel: hijriOffsetLabel,
          onChanged: (v) =>
              cubit.changeSettings(settings.copyWith(hijriOffset: v)),
        ),
        if (hijri != null)
          Text(
            'التاريخ الهجري اليوم: ${hijri.label}',
            style: AppTypography.labelRegular.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
      ],
    );
  }
}

class _TuneCard extends StatelessWidget {
  const _TuneCard();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PrayerTimesCubit>();
    final settings = context.select<PrayerTimesCubit, PrayerSettings>(
      (c) => c.state.settings,
    );

    String minutes(int m) =>
        m == 0 ? '0 د' : '${m > 0 ? '+' : '−'}${m.abs()} د';

    return PrayerFormCard(
      title: 'تعديل الدقائق',
      subtitle:
          'يُضاف إلى الوقت المحسوب أو يُطرح منه، من 30 دقيقة قبله '
          'إلى 30 دقيقة بعده.',
      children: [
        for (final prayer in Prayer.values)
          PrayerStepper(
            key: ValueKey('tune-${prayer.name}-${settings.tuneOf(prayer)}'),
            label: prayer.label,
            value: settings.tuneOf(prayer),
            min: -PrayerSettings.maxTune,
            max: PrayerSettings.maxTune,
            valueLabel: minutes,
            onChanged: (m) {
              // The latest settings: another stepper may have changed them.
              final current = cubit.state.settings;
              cubit.changeSettings(
                current.copyWith(tune: {...current.tune, prayer: m}),
              );
            },
          ),
      ],
    );
  }
}

class _ResetCard extends StatelessWidget {
  const _ResetCard();

  Future<void> _reset(BuildContext context) async {
    final cubit = context.read<PrayerTimesCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('استعادة الإعدادات الافتراضية؟'),
        content: const Text(
          'تعود طريقة الحساب ومذهب العصر وتعديل الهجري والدقائق إلى ما كانت '
          'عليه أول مرة. تبقى مدينتك كما هي.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('استعادة'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await cubit.changeSettings(const PrayerSettings());
  }

  @override
  Widget build(BuildContext context) {
    return PrayerFormCard(
      title: 'استعادة الإعدادات الافتراضية',
      subtitle:
          'إعادة كل إعدادات هذه الصفحة إلى ما كانت عليه أول مرة، مع بقاء '
          'مدينتك المحفوظة كما هي.',
      children: [
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: AppButton.secondary(
            label: 'استعادة الافتراضي',
            onPressed: () => _reset(context),
          ),
        ),
      ],
    );
  }
}
