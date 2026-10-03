import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manara/core/router/app_routes.dart';
import 'package:manara/core/theme/theme.dart';
import 'package:manara/core/widgets/app_nav_bar.dart';

class _FooterLink {
  const _FooterLink(this.label, [this.route]);

  final String label;
  final String? route;
}

class _FooterColumn {
  const _FooterColumn(this.title, this.links);

  final String title;
  final List<_FooterLink> links;
}

/// Site footer from Figma ("Footer"): brand, four link columns, copyright.
class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  static const Color _background = AppColors.green900;
  static const Color _heading = AppColors.lightGold500;
  static const Color _link = AppColors.beige500;
  static const Color _copyright = Color(0xFFB8A886);

  static const _columns = [
    _FooterColumn('القرآن الكريم', [
      _FooterLink('المصحف', AppRoutes.quran),
      _FooterLink('التفسير'),
      _FooterLink('التلاوة'),
      _FooterLink('الختمة'),
      _FooterLink('المحفوظات'),
    ]),
    _FooterColumn('العبادات', [
      _FooterLink('الصلاة', AppRoutes.prayer),
      _FooterLink('الأذكار'),
      _FooterLink('التسبيح'),
      _FooterLink('القبلة', AppRoutes.qibla),
      _FooterLink('رمضان'),
    ]),
    _FooterColumn('المحتوى', [
      _FooterLink('الأحاديث'),
      _FooterLink('السيرة النبوية'),
      _FooterLink('قصص الأنبياء'),
      _FooterLink('على خطاهم'),
      _FooterLink('محتوى الأطفال'),
    ]),
    _FooterColumn('المزيد', [
      _FooterLink('الشروط والأحكام'),
      _FooterLink('سياسة الخصوصية'),
      _FooterLink('تواصل معنا'),
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 900;

    return ColoredBox(
      color: _background,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            wide ? 60 : AppSpacing.lg,
            48,
            wide ? 60 : AppSpacing.lg,
            36,
          ),
          child: Column(
            children: [
              if (wide)
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 244),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Center(child: _Columns(spacing: 126))),
                      SizedBox(width: 24),
                      _Brand(),
                    ],
                  ),
                ),
              if (wide)
                const SizedBox(height: 24)
              else ...[
                const _Brand(),
                const SizedBox(height: AppSpacing.xl),
                const _Columns(spacing: AppSpacing.xl),
                const SizedBox(height: AppSpacing.xl),
              ],
              Text(
                '© ${DateTime.now().year} منارة. جميع الحقوق محفوظة.',
                style: AppTypography.smallRegular.copyWith(
                  fontSize: 10,
                  color: _copyright,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: Column(
        children: [
          Text(
            'منارة | Manara',
            style: AppTypography.bodyLargeBold.copyWith(
              color: AppColors.white500,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'رفيقك للقرآن والعبادة والمعرفة الإسلامية',
            textAlign: TextAlign.center,
            style: AppTypography.smallRegular.copyWith(
              color: AppFooter._heading,
            ),
          ),
        ],
      ),
    );
  }
}

class _Columns extends StatelessWidget {
  const _Columns({required this.spacing});

  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: AppSpacing.xl,
      alignment: WrapAlignment.center,
      children: [
        for (final column in AppFooter._columns) _Column(column: column),
      ],
    );
  }
}

class _Column extends StatelessWidget {
  const _Column({required this.column});

  final _FooterColumn column;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          column.title,
          style: AppTypography.bodyLargeBold.copyWith(
            color: AppFooter._heading,
          ),
        ),
        for (final link in column.links)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 10),
            child: InkWell(
              onTap: () {
                final route = link.route;
                if (route == null) {
                  showComingSoon(context);
                } else {
                  context.go(route);
                }
              },
              child: Text(
                link.label,
                style: AppTypography.captionRegular.copyWith(
                  color: AppFooter._link,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
