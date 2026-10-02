import 'package:manara/features/quran/domain/entities/ayah.dart';
import 'package:manara/features/quran/domain/entities/mushaf_page.dart';
import 'package:manara/features/quran/domain/entities/surah.dart';

const fatiha = Surah(
  id: 1,
  nameArabic: 'الفاتحة',
  revelationPlace: RevelationPlace.makkah,
  versesCount: 7,
  firstPage: 1,
  lastPage: 1,
);

const baqarah = Surah(
  id: 2,
  nameArabic: 'البقرة',
  revelationPlace: RevelationPlace.madinah,
  versesCount: 286,
  firstPage: 2,
  lastPage: 49,
);

const imran = Surah(
  id: 3,
  nameArabic: 'آل عمران',
  revelationPlace: RevelationPlace.madinah,
  versesCount: 200,
  firstPage: 50,
  lastPage: 76,
);

const surahs = [fatiha, baqarah, imran];

Ayah ayah(int surah, int number, {int page = 2, String? text}) => Ayah(
  surahNumber: surah,
  number: number,
  text: text ?? 'نص الآية $number',
  pageNumber: page,
  juzNumber: 1,
);

MushafPage pageOf(int number, {int surah = 2, int firstAyah = 1}) {
  return MushafPage(
    number: number,
    ayahs: [
      for (var i = 0; i < 3; i++) ayah(surah, firstAyah + i, page: number),
    ],
  );
}

/// A payload shaped like Quran.com `/verses/by_page/{n}`.
Map<String, dynamic> versesJson() => {
  'verses': [
    {
      'id': 13,
      'verse_number': 6,
      'verse_key': '2:6',
      'text_uthmani': 'إِنَّ ٱلَّذِينَ كَفَرُوا۟',
      'page_number': 3,
      'juz_number': 1,
    },
    {
      'id': 14,
      'verse_number': 7,
      'verse_key': '2:7',
      'text_uthmani': 'خَتَمَ ٱللَّهُ',
      'page_number': 3,
      'juz_number': 1,
    },
  ],
};

/// A payload shaped like Quran.com `/chapters?language=ar`.
Map<String, dynamic> chaptersJson() => {
  'chapters': [
    {
      'id': 2,
      'revelation_place': 'madinah',
      'name_arabic': 'البقرة',
      'verses_count': 286,
      'pages': [2, 49],
    },
    {
      'id': 1,
      'revelation_place': 'makkah',
      'name_arabic': 'الفاتحة',
      'verses_count': 7,
      'pages': [1, 1],
    },
  ],
};

/// Al-Mukhtasar on 2:6, verbatim from QuranEnc.
const mukhtasar2v6 =
    'إن الذين حقت عليهم كلمة الله بعدم الإيمان مستمرون على ضلالهم وعنادهم، '
    'فإنذارك لهم وعدمه سواء.';

/// Al-Mukhtasar on 2:7, verbatim from QuranEnc.
const mukhtasar2v7 =
    'لأن الله طبع على قلوبهم فأغلقها على ما فيها من باطل، وطبع على سمعهم فلا '
    'يسمعون الحق سماع قَبول وانقياد، وجعل على أبصارهم غطاء فلا يبصرون الحق '
    'مع وضوحه، ولهم في الآخرة عذاب عظيم.';

/// A payload shaped like QuranEnc `/translation/sura/arabic_mokhtasar/2`,
/// trimmed to two ayahs.
Map<String, dynamic> mukhtasarSurah2Json() => {
  'result': [
    {
      'id': '13',
      'sura': '2',
      'aya': '6',
      'arabic_text': 'إِنَّ ٱلَّذِينَ كَفَرُوا۟',
      'translation': mukhtasar2v6,
      'footnotes': null,
    },
    {
      'id': '14',
      'sura': '2',
      'aya': '7',
      'arabic_text': 'خَتَمَ ٱللَّهُ',
      'translation': mukhtasar2v7,
      'footnotes': null,
    },
  ],
};

/// A payload shaped like Quran.com `/tafsirs/14/by_page/3` (placeholder
/// text, the real one is HTML of the same shape).
Map<String, dynamic> ibnKathirPage3Json() => {
  'tafsirs': [
    {
      'id': 1,
      'resource_id': 14,
      'verse_key': '2:6',
      'language_id': 9,
      'text': '<p lang="ar" class="ar ">نص تجريبي أول</p>',
      'slug': 'ar-tafsir-ibn-kathir',
    },
    {
      'id': 2,
      'resource_id': 14,
      'verse_key': '2:7',
      'language_id': 9,
      'text': '<p lang="ar" class="ar ">نص تجريبي ثانٍ</p>',
      'slug': 'ar-tafsir-ibn-kathir',
    },
  ],
};
