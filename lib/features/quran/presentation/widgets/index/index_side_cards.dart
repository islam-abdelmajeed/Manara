import 'package:flutter/material.dart';
import 'package:manara/core/theme/theme.dart';
import 'package:manara/core/widgets/app_icon.dart';
import 'package:manara/features/quran/presentation/cubit/quran_index_cubit.dart';
import 'package:manara/features/quran/presentation/widgets/index/index_style.dart';

class _SideCard extends StatelessWidget {
  const _SideCard({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const ShapeDecoration(
        color: IndexStyle.cardColor,
        shape: IndexStyle.cardShape,
      ),
      child: Padding(
        padding:
            padding ??
            const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: 18),
        child: child,
      ),
    );
  }
}

TextStyle get _titleStyle =>
    AppTypography.captionBold.copyWith(color: IndexStyle.titleColor);

TextStyle _smallStyle(Color color) =>
    AppTypography.labelRegular.copyWith(color: color, height: 16 / 12);

/// "وردي اليومي": today's pages against [ReaderProgress.dailyWirdPages].
class DailyWirdCard extends StatelessWidget {
  const DailyWirdCard({
    required this.pagesRead,
    required this.goal,
    required this.onStart,
    super.key,
  });

  final int pagesRead;
  final int goal;
  final VoidCallback onStart;

  String get _buttonLabel {
    if (pagesRead >= goal) return 'أتممت ورد اليوم';
    return pagesRead == 0 ? 'ابدأ ورد اليوم' : 'أكمل ورد اليوم';
  }

  @override
  Widget build(BuildContext context) {
    final progress = goal == 0 ? 0.0 : (pagesRead / goal).clamp(0.0, 1.0);

    return _SideCard(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 23, 24, 19),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('وردي اليومي', style: _titleStyle),
                    const SizedBox(width: 6),
                    const AppIcon(
                      AppIcons.stars,
                      size: 20,
                      color: AppColors.darkBrown900,
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Text(
                  'استمر في رحلتك اليومية',
                  style: _smallStyle(AppColors.gold500),
                ),
                const SizedBox(height: 8),
                Text(
                  'اقرأ وردك اليومي من القرآن الكريم',
                  style: _smallStyle(IndexStyle.mutedText),
                ),
                const SizedBox(height: 10),
                Semantics(
                  label: 'تقدم الورد',
                  value: '$pagesRead من $goal صفحات',
                  child: _WirdProgress(value: progress),
                ),
                const SizedBox(height: 21),
                IndexPillButton(label: _buttonLabel, onPressed: onStart),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: AppSpacing.md),
            child: Image.asset(
              AppImages.dailyWirdFlower,
              width: 57,
              excludeFromSemantics: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _WirdProgress extends StatelessWidget {
  const _WirdProgress({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 165),
      child: ClipRRect(
        borderRadius: AppRadius.pillAll,
        child: SizedBox(
          height: 6,
          child: ColoredBox(
            color: AppColors.darkBrown100,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: FractionallySizedBox(
                widthFactor: value,
                heightFactor: 1,
                child: const ColoredBox(color: AppColors.primary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "مواصلة القراءة": where the reader stopped, or an invitation to start.
class ContinueReadingCard extends StatelessWidget {
  const ContinueReadingCard({
    required this.lastRead,
    required this.hasStarted,
    required this.onContinue,
    super.key,
  });

  /// `null` before any reading or while the last page loads.
  final LastReadPosition? lastRead;
  final bool hasStarted;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final position = lastRead;

    return _SideCard(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 20, 24, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('مواصلة القراءة', style: _titleStyle),
          const SizedBox(height: 11),
          Text(
            hasStarted ? 'آخر سورة قرأتها' : 'لم تبدأ القراءة بعد',
            style: _smallStyle(AppColors.textHint),
          ),
          const SizedBox(height: 11),
          Text(
            position == null
                ? (hasStarted ? '…' : 'سورة الفاتحة')
                : 'سورة ${position.surah.nameArabic}',
            style: AppTypography.captionBold.copyWith(color: AppColors.gold500),
          ),
          Text(
            'الآية ${position?.ayahNumber ?? 1}',
            style: _smallStyle(IndexStyle.mutedText),
          ),
          const SizedBox(height: 12),
          IndexPillButton(
            label: hasStarted ? 'متابعة القراءة' : 'ابدأ القراءة',
            onPressed: onContinue,
            expand: true,
          ),
        ],
      ),
    );
  }
}

/// A surah listed in "السور الأكثر قراءة".
class PopularSurah {
  const PopularSurah(this.name, this.firstPage);

  final String name;
  final int firstPage;
}

/// "السور الأكثر قراءة": a fixed list of commonly read surahs.
class MostReadCard extends StatelessWidget {
  const MostReadCard({required this.onOpen, super.key});

  final ValueChanged<PopularSurah> onOpen;

  static const surahs = [
    PopularSurah('الملك', 562),
    PopularSurah('الكهف', 293),
    PopularSurah('يس', 440),
    PopularSurah('الرحمن', 531),
    PopularSurah('الواقعة', 534),
  ];

  @override
  Widget build(BuildContext context) {
    return _SideCard(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 19, 24, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('السور الأكثر قراءة', style: _titleStyle),
          const SizedBox(height: 15),
          for (final (i, surah) in surahs.indexed) ...[
            if (i > 0) const SizedBox(height: 14),
            _MostReadItem(
              rank: i + 1,
              name: 'سورة ${surah.name}',
              onTap: () => onOpen(surah),
            ),
          ],
        ],
      ),
    );
  }
}

class _MostReadItem extends StatelessWidget {
  const _MostReadItem({
    required this.rank,
    required this.name,
    required this.onTap,
  });

  final int rank;
  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$rank، $name',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.smAll,
        child: Row(
          children: [
            SizedBox(
              width: 12,
              child: Text(
                '$rank',
                textAlign: TextAlign.center,
                style: AppTypography.captionBold.copyWith(
                  color: AppColors.gold500,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                name,
                style: AppTypography.captionRegular.copyWith(
                  color: IndexStyle.titleColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
