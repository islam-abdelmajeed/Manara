import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manara/core/constants/app_constants.dart';
import 'package:manara/core/router/app_routes.dart';
import 'package:manara/core/theme/theme.dart';
import 'package:manara/core/widgets/app_icon.dart';
import 'package:manara/core/widgets/app_toast.dart';

/// Top-level sections shown in the navigation bar, in reading order.
enum NavItem {
  home('الرئيسية', AppRoutes.home),
  quran('القرآن الكريم', AppRoutes.quran),
  prayer('الصلاة'),
  adhkar('الأذكار'),
  hadith('الأحاديث'),
  rooms('الغرف'),
  more('المزيد');

  const NavItem(this.label, [this.route]);

  final String label;

  /// `null` until the section is built.
  final String? route;
}

const String _comingSoon = 'قريبًا إن شاء الله';

/// Shows the "coming soon" toast used by sections that are not built yet.
void showComingSoon(BuildContext context) => showAppToast(context, _comingSoon);

SnackBar comingSoonSnackBar() => appToastSnackBar(_comingSoon);

void _open(BuildContext context, NavItem item) {
  final route = item.route;
  if (route == null) {
    showComingSoon(context);
  } else {
    context.go(route);
  }
}

/// Colors of the navigation bar. Figma reuses a light-background component
/// here, which leaves links and icons green on green; these are the light
/// equivalents from the same palette.
abstract final class _NavColors {
  static const Color foreground = AppColors.gold100;
  static const Color activeBackground = AppColors.gold100;
  static const Color activeForeground = AppColors.primary;
}

/// App navigation bar from Figma ("Frame 25"): brand, section links and
/// actions. Below [compactBreakpoint] the links move into a drawer.
class AppNavBar extends StatelessWidget implements PreferredSizeWidget {
  const AppNavBar({required this.active, super.key});

  final NavItem active;

  static const double compactBreakpoint = 1200;
  static const double _height = 97;
  static const double _compactHeight = 64;

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < compactBreakpoint;

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    final compact = isCompact(context);
    final padding = MediaQuery.paddingOf(context).top;

    return Container(
      height: (compact ? _compactHeight : _height) + padding,
      padding: EdgeInsetsDirectional.only(
        top: padding,
        start: compact ? AppSpacing.md : 36,
        end: compact ? AppSpacing.xs : 36,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: Color(0x40000000),
            offset: Offset(0, 4),
            blurRadius: 127,
          ),
        ],
      ),
      child: compact ? const _CompactBar() : _WideBar(active: active),
    );
  }
}

class _WideBar extends StatelessWidget {
  const _WideBar({required this.active});

  final NavItem active;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _Brand(),
        Expanded(
          child: Center(
            // Shrinks rather than overflowing if the links outgrow the space.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final item in NavItem.values) ...[
                    _NavLink(item: item, active: item == active),
                    if (item != NavItem.values.last) const SizedBox(width: 10),
                  ],
                ],
              ),
            ),
          ),
        ),
        const _Actions(),
      ],
    );
  }
}

class _CompactBar extends StatelessWidget {
  const _CompactBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _Brand(compact: true),
        const Spacer(),
        const _ActionIcon(icon: AppIcons.search, tooltip: 'بحث'),
        IconButton(
          tooltip: 'القائمة',
          onPressed: () => Scaffold.of(context).openEndDrawer(),
          icon: const AppIcon(
            AppIcons.options,
            size: 30,
            color: _NavColors.foreground,
          ),
        ),
      ],
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: AppConstants.appName,
      child: InkWell(
        onTap: () => context.go(AppRoutes.home),
        borderRadius: AppRadius.mdAll,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              AppImages.logo,
              width: compact ? 42 : 75,
              height: compact ? 45 : 80,
              excludeFromSemantics: true,
            ),
            Text(
              AppConstants.appName,
              style:
                  (compact ? AppTypography.h4Bold : AppTypography.displayBold)
                      .copyWith(color: _NavColors.foreground),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink({required this.item, required this.active});

  final NavItem item;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      child: Material(
        color: active ? _NavColors.activeBackground : Colors.transparent,
        borderRadius: AppRadius.mdAll,
        child: InkWell(
          onTap: active ? null : () => _open(context, item),
          borderRadius: AppRadius.mdAll,
          hoverColor: Colors.white.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              item.label,
              style:
                  (active
                          ? AppTypography.bodyLargeBold
                          : AppTypography.bodyLargeMedium)
                      .copyWith(
                        color: active
                            ? _NavColors.activeForeground
                            : _NavColors.foreground,
                      ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionIcon(icon: AppIcons.search, tooltip: 'بحث'),
        SizedBox(width: 20),
        _ActionIcon(icon: AppIcons.notifications, tooltip: 'الإشعارات'),
        SizedBox(width: 29),
        _LoginButton(),
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.icon, required this.tooltip});

  final String icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => showComingSoon(context),
      tooltip: tooltip,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      padding: EdgeInsets.zero,
      icon: AppIcon(icon, size: 35, color: _NavColors.foreground),
    );
  }
}

/// Shown instead of the signed-in user chip until accounts exist
/// (style from the Figma hadith page navbar).
class _LoginButton extends StatelessWidget {
  const _LoginButton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white50,
      borderRadius: AppRadius.smAll,
      child: InkWell(
        onTap: () => showComingSoon(context),
        borderRadius: AppRadius.smAll,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 145, minHeight: 48),
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                'تسجيل الدخول',
                style: AppTypography.captionBold.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Drawer with the navigation links for compact widths.
class AppNavDrawer extends StatelessWidget {
  const AppNavDrawer({required this.active, super.key});

  final NavItem active;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.primary,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const Align(
              alignment: AlignmentDirectional.centerStart,
              child: _Brand(compact: true),
            ),
            const SizedBox(height: AppSpacing.lg),
            for (final item in NavItem.values)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: _DrawerLink(item: item, active: item == active),
              ),
            const SizedBox(height: AppSpacing.md),
            const _LoginButton(),
          ],
        ),
      ),
    );
  }
}

class _DrawerLink extends StatelessWidget {
  const _DrawerLink({required this.item, required this.active});

  final NavItem item;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? _NavColors.activeBackground : Colors.transparent,
      borderRadius: AppRadius.mdAll,
      child: InkWell(
        borderRadius: AppRadius.mdAll,
        onTap: () {
          // Resolve before closing: the drawer's context goes away with it.
          final router = GoRouter.of(context);
          final messenger = ScaffoldMessenger.of(context);
          Navigator.of(context).pop();
          if (active) return;
          final route = item.route;
          if (route == null) {
            messenger.showSnackBar(comingSoonSnackBar());
          } else {
            router.go(route);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Text(
            item.label,
            style: AppTypography.bodyLargeMedium.copyWith(
              color: active
                  ? _NavColors.activeForeground
                  : _NavColors.foreground,
            ),
          ),
        ),
      ),
    );
  }
}
