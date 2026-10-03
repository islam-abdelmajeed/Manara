/// Aladhan calculation methods (`GET /v1/methods`), with Arabic names of
/// the authorities. Ids are Aladhan's; 6 is unused and 99 (custom) is not
/// offered.
enum PrayerMethod {
  egypt(5, 'الهيئة المصرية العامة للمساحة'),
  mwl(3, 'رابطة العالم الإسلامي'),
  makkah(4, 'جامعة أم القرى، مكة المكرمة'),
  karachi(1, 'جامعة العلوم الإسلامية، كراتشي'),
  isna(2, 'الجمعية الإسلامية لأمريكا الشمالية'),
  gulf(8, 'منطقة الخليج'),
  kuwait(9, 'الكويت'),
  qatar(10, 'قطر'),
  dubai(16, 'دبي (تجريبي)'),
  jordan(23, 'وزارة الأوقاف والشؤون والمقدسات الإسلامية، الأردن'),
  algeria(19, 'الجزائر'),
  tunisia(18, 'تونس'),
  morocco(21, 'المغرب'),
  turkey(13, 'رئاسة الشؤون الدينية، تركيا (تجريبي)'),
  tehran(7, 'معهد الجيوفيزياء، جامعة طهران'),
  jafari(0, 'الشيعة الإمامية، معهد ليفا، قم'),
  singapore(11, 'المجلس الإسلامي، سنغافورة'),
  jakim(17, 'إدارة التنمية الإسلامية الماليزية (جاكيم)'),
  kemenag(20, 'وزارة الشؤون الدينية، إندونيسيا'),
  russia(14, 'الإدارة الدينية لمسلمي روسيا'),
  france(12, 'اتحاد المنظمات الإسلامية في فرنسا'),
  portugal(22, 'الجماعة الإسلامية في لشبونة'),
  moonsighting(15, 'لجنة رؤية الهلال العالمية');

  const PrayerMethod(this.id, this.label);

  /// Aladhan `method`.
  final int id;

  final String label;

  static PrayerMethod? byId(int id) {
    for (final m in values) {
      if (m.id == id) return m;
    }
    return null;
  }
}
