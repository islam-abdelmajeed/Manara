import 'package:flutter/material.dart';
import 'package:manara/core/theme/theme.dart';

/// Framed surah title, followed by the basmala, where a surah starts.
class SurahBanner extends StatelessWidget {
  const SurahBanner({
    required this.surahNumber,
    required this.name,
    required this.style,
    super.key,
  });

  final int surahNumber;
  final String name;

  /// The Quran text style the banner is sized from.
  final TextStyle style;

  static const _basmala = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';

  // Al-Fatiha carries the basmala as its first ayah and At-Tawbah has none.
  bool get _showBasmala => surahNumber != 1 && surahNumber != 9;

  @override
  Widget build(BuildContext context) {
    final titleSize = (style.fontSize ?? 30) * 0.85;
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: AppSpacing.xs),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsetsDirectional.symmetric(
              vertical: AppSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: AppRadius.smAll,
              border: Border.all(color: AppColors.primary, width: 1.5),
            ),
            child: Text(
              'سُورَةُ $name',
              textAlign: TextAlign.center,
              style: style.copyWith(fontSize: titleSize, height: 1.8),
            ),
          ),
          if (_showBasmala)
            Text(_basmala, textAlign: TextAlign.center, style: style),
        ],
      ),
    );
  }
}
