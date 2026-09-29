import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:manara/core/theme/theme.dart';
import 'package:manara/core/widgets/widgets.dart';
import 'package:manara/features/hadith/domain/entities/hadith.dart';

/// "حديث اليوم" card. Uses the Figma artwork (lantern, pattern) at design
/// width and a plain version of it on narrow screens.
class HadithOfDayCard extends StatelessWidget {
  const HadithOfDayCard({required this.hadith, super.key});

  final Hadith? hadith;

  static const Size designSize = Size(653, 343);
  static const double minDesignWidth = 490;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= minDesignWidth) {
          return DesignBox(
            size: designSize,
            child: _DesignLayout(hadith: hadith),
          );
        }
        return _CompactLayout(hadith: hadith);
      },
    );
  }
}

abstract final class _Style {
  static const border = AppColors.gold300;
  static const radius = BorderRadius.all(Radius.circular(20));
  static const shadow = [
    BoxShadow(color: Color(0x40000000), offset: Offset(0, 4), blurRadius: 20),
  ];

  static final title = AppTypography.h1Medium.copyWith(
    color: AppColors.darkBrown700,
  );
  static final intro = AppTypography.bodyLargeMedium.copyWith(
    color: Colors.black,
  );
  static final hadith = AppTypography.h2Bold.copyWith(color: Colors.black);
  static final source = AppTypography.captionMedium.copyWith(
    color: Colors.black,
  );

  /// The Figma intro reads "صل"; "صلى" is the correct spelling.
  static const introText = 'قال رسول الله صلى الله عليه وسلم';
}

class _DesignLayout extends StatelessWidget {
  const _DesignLayout({required this.hadith});

  final Hadith? hadith;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        borderRadius: _Style.radius,
        boxShadow: _Style.shadow,
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: _Style.radius,
        border: Border.all(
          color: _Style.border,
          width: 3,
          strokeAlign: BorderSide.strokeAlignCenter,
        ),
      ),
      child: ClipRRect(
        borderRadius: _Style.radius,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                AppImages.cardHadith,
                fit: BoxFit.fill,
                excludeFromSemantics: true,
              ),
            ),
            Positioned(
              right: 40,
              top: 33,
              child: Text('حديث اليوم', style: _Style.title),
            ),
            // Centered on the Figma text column (x = 332); the source sits
            // under the hadith at the column's reading end, as in Figma.
            Positioned(
              left: 96,
              top: 97,
              width: 473,
              child: _Body(hadith: hadith, maxHadithHeight: 108),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 281,
              height: 40,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: _Actions(hadith: hadith, spacing: 112),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactLayout extends StatelessWidget {
  const _CompactLayout({required this.hadith});

  final Hadith? hadith;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: AlignmentDirectional.centerEnd,
          end: AlignmentDirectional.centerStart,
          colors: [Color(0xFFF6E8DA), Color(0xFFFCF6F0), Color(0xFFF1E0C9)],
        ),
        borderRadius: _Style.radius,
        border: Border.all(color: _Style.border, width: 3),
        boxShadow: _Style.shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'حديث اليوم',
            style: AppTypography.h4Medium.copyWith(
              color: AppColors.darkBrown700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _Body(hadith: hadith, compact: true),
          const SizedBox(height: AppSpacing.md),
          SizedBox(height: 44, child: _Actions(hadith: hadith, spacing: 40)),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.hadith,
    this.maxHadithHeight,
    this.compact = false,
  });

  final Hadith? hadith;

  /// Keeps long hadiths inside the design layout by scaling them down.
  final double? maxHadithHeight;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final current = hadith;
    final hadithStyle = compact
        ? AppTypography.subtitleBold.copyWith(color: Colors.black)
        : _Style.hadith;

    Widget text = Text(
      current?.text ?? '',
      textAlign: TextAlign.center,
      style: hadithStyle,
    );
    if (!compact) {
      // Figma wraps the hadith in a narrow centered column (267px for its
      // two-line sample); 380 keeps typical hadiths to two lines.
      text = Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: text,
        ),
      );
    }
    if (maxHadithHeight != null) {
      text = ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHadithHeight!),
        child: FittedBox(fit: BoxFit.scaleDown, child: text),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _Style.introText,
          textAlign: TextAlign.center,
          style: compact ? AppTypography.bodyMedium : _Style.intro,
        ),
        SizedBox(height: compact ? AppSpacing.xs : 16),
        text,
        const SizedBox(height: 9),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Text(current?.source ?? '', style: _Style.source),
        ),
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.hadith, required this.spacing});

  final Hadith? hadith;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final current = hadith;
    final actions = [
      (AppIcons.bookmarkPosition, 'حفظ الحديث', () => showComingSoon(context)),
      (AppIcons.readingMode, 'قراءة الشرح', () => showComingSoon(context)),
      (AppIcons.share, 'مشاركة', () => showComingSoon(context)),
      (
        AppIcons.copy,
        'نسخ الحديث',
        () async {
          if (current == null) return;
          await Clipboard.setData(
            ClipboardData(
              text:
                  '${_Style.introText}: «${current.text}» (${current.source})',
            ),
          );
          if (context.mounted) showAppToast(context, 'تم نسخ الحديث');
        },
      ),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) SizedBox(width: spacing - 19),
          IconButton(
            onPressed: actions[i].$3,
            tooltip: actions[i].$2,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            icon: AppIcon(actions[i].$1, size: 25, color: AppColors.primary),
          ),
        ],
      ],
    );
  }
}
