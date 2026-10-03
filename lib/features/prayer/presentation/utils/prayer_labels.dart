import 'package:manara/features/prayer/domain/entities/prayer_settings.dart';

/// Arabic names of the calculation options shown in settings.
extension AsrSchoolLabel on AsrSchool {
  String get label => switch (this) {
    AsrSchool.standard => 'الجمهور: الشافعي والمالكي والحنبلي',
    AsrSchool.hanafi => 'الحنفي',
  };

  /// How the start of Asr is measured.
  String get detail => switch (this) {
    AsrSchool.standard => 'حين يصير ظل الشيء مثله',
    AsrSchool.hanafi => 'حين يصير ظل الشيء مثليه',
  };
}

extension HighLatitudeRuleLabel on HighLatitudeRule {
  String get label => switch (this) {
    HighLatitudeRule.middleOfNight => 'منتصف الليل',
    HighLatitudeRule.oneSeventh => 'سُبع الليل',
    HighLatitudeRule.angleBased => 'نسبة الزاوية',
  };

  /// As defined by PrayTimes (praytimes.org/docs/calculation), which
  /// Aladhan follows. Used only where twilight lasts all night.
  String get detail => switch (this) {
    HighLatitudeRule.middleOfNight =>
      'الفجر والعشاء عند منتصف ما بين الغروب والشروق',
    HighLatitudeRule.oneSeventh =>
      'يُقسم ما بين الغروب والشروق سبعة أجزاء: العشاء بعد الجزء الأول، '
          'والفجر عند بداية الجزء السابع',
    HighLatitudeRule.angleBased =>
      'جزء من الليل بقدر زاوية الشفق من ستين؛ فزاوية 15 تعني ربع الليل',
  };
}

/// `اليوم بحسب الحساب`, `متقدم يومًا`, `متأخر يومين`…
String hijriOffsetLabel(int offset) => switch (offset) {
  0 => 'بحسب الحساب',
  1 => 'متقدم يومًا',
  2 => 'متقدم يومين',
  -1 => 'متأخر يومًا',
  -2 => 'متأخر يومين',
  _ => '$offset',
};
