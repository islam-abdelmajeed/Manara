import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:manara/core/theme/theme.dart';

class MoreMenuLink {
  const MoreMenuLink(this.label, [this.route]);

  final String label;

  /// `null` until the section is built.
  final String? route;
}

class MoreMenuGroup {
  const MoreMenuGroup(this.title, this.links);

  final String title;
  final List<MoreMenuLink> links;
}

/// Sections behind the navigation bar's "المزيد" link, in reading order
/// (Figma "Desktop - 3").
const List<MoreMenuGroup> moreMenuGroups = [
  MoreMenuGroup('القرآن والتعلم', [
    MoreMenuLink('التسميع'),
    MoreMenuLink('التفسير'),
    MoreMenuLink('التلاوات'),
    MoreMenuLink('علامات المصحف'),
    MoreMenuLink('الختمات'),
    MoreMenuLink('غرف التسميع'),
  ]),
  MoreMenuGroup('المحتوى الإسلامي', [
    MoreMenuLink('السيرة النبوية'),
    MoreMenuLink('قصص الأنبياء'),
    MoreMenuLink('على خطاهم'),
    MoreMenuLink('الخطب والدروس'),
    MoreMenuLink('تحفة الأطفال'),
    MoreMenuLink('الصوت والفيديو'),
  ]),
  MoreMenuGroup('الأدوات', [
    MoreMenuLink('التقويم الهجري'),
    MoreMenuLink('رمضان'),
    MoreMenuLink('المحفوظات'),
    MoreMenuLink('بدون إنترنت'),
    MoreMenuLink('التنبيهات'),
  ]),
  MoreMenuGroup('حسابك', [
    MoreMenuLink('الملف الشخصي'),
    MoreMenuLink('إحصائياتك'),
    MoreMenuLink('إنجازاتك'),
    MoreMenuLink('المفضلة'),
    MoreMenuLink('الإعدادات'),
  ]),
];

/// Full-width panel opened from the navigation bar's "المزيد" link
/// (Figma "Desktop - 3"): the [moreMenuGroups] in columns split by rules.
class MoreMenuPanel extends StatelessWidget {
  const MoreMenuPanel({
    required this.onSelected,
    required this.onDismiss,
    super.key,
  });

  final ValueChanged<MoreMenuLink> onSelected;

  /// Called when Escape is pressed.
  final VoidCallback onDismiss;

  static const double height = 311;
  static const double _columnsTop = 13;
  static const double _columnsHeight = 223;
  static const double _gap = 57;
  static const double _ruleHeight = 211;
  static const Color _rule = Color(0x4D000000);

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): onDismiss},
      child: Focus(
        autofocus: true,
        child: Material(
          color: AppColors.green100,
          child: SizedBox(
            height: height,
            child: Padding(
              padding: const EdgeInsets.only(top: _columnsTop),
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  height: _columnsHeight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final group in moreMenuGroups) ...[
                        if (group != moreMenuGroups.first) ...[
                          const SizedBox(width: _gap),
                          const SizedBox(
                            width: 1,
                            height: _ruleHeight,
                            child: ColoredBox(color: _rule),
                          ),
                          const SizedBox(width: _gap),
                        ],
                        _Group(group: group, onSelected: onSelected),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.group, required this.onSelected});

  final MoreMenuGroup group;
  final ValueChanged<MoreMenuLink> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            group.title,
            style: AppTypography.bodyLargeMedium.copyWith(
              color: AppColors.darkBrown500,
            ),
          ),
        ),
        const SizedBox(height: 5),
        const SizedBox(
          width: 40,
          height: 2,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.gold500,
              borderRadius: BorderRadius.all(Radius.circular(1)),
            ),
          ),
        ),
        for (final link in group.links) ...[
          const SizedBox(height: 10),
          _Link(link: link, onTap: () => onSelected(link)),
        ],
      ],
    );
  }
}

class _Link extends StatefulWidget {
  const _Link({required this.link, required this.onTap});

  final MoreMenuLink link;
  final VoidCallback onTap;

  @override
  State<_Link> createState() => _LinkState();
}

class _LinkState extends State<_Link> {
  static const Color _color = Color(0xFF5C4D2E);

  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: InkWell(
        onTap: widget.onTap,
        onHover: (hovered) => setState(() => _hovered = hovered),
        onFocusChange: (focused) => setState(() => _hovered = focused),
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Text(
          widget.link.label,
          style: AppTypography.captionRegular.copyWith(
            color: _hovered ? AppColors.primary : _color,
            decoration: _hovered ? TextDecoration.underline : null,
            decorationColor: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
