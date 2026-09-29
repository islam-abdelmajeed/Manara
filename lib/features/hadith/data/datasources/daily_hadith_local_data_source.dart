import 'package:injectable/injectable.dart';
import 'package:manara/features/hadith/domain/entities/hadith.dart';

abstract interface class DailyHadithLocalDataSource {
  List<Hadith> all();
}

/// Short, well-known authentic hadiths used until the hadith section has a
/// real data source.
@LazySingleton(as: DailyHadithLocalDataSource)
class DailyHadithLocalDataSourceImpl implements DailyHadithLocalDataSource {
  const DailyHadithLocalDataSourceImpl();

  static const List<Hadith> _hadiths = [
    Hadith(
      text: 'مَنْ دَلَّ عَلَى خَيْرٍ فَلَهُ مِثْلُ أَجْرِ فَاعِلِهِ',
      source: 'رواه مسلم',
    ),
    Hadith(
      text:
          'إِنَّمَا الْأَعْمَالُ بِالنِّيَّاتِ، وَإِنَّمَا لِكُلِّ امْرِئٍ مَا نَوَى',
      source: 'متفق عليه',
    ),
    Hadith(
      text: 'خَيْرُكُمْ مَنْ تَعَلَّمَ الْقُرْآنَ وَعَلَّمَهُ',
      source: 'رواه البخاري',
    ),
    Hadith(text: 'الْكَلِمَةُ الطَّيِّبَةُ صَدَقَةٌ', source: 'متفق عليه'),
    Hadith(
      text:
          'لَا يُؤْمِنُ أَحَدُكُمْ حَتَّى يُحِبَّ لِأَخِيهِ مَا يُحِبُّ لِنَفْسِهِ',
      source: 'متفق عليه',
    ),
    Hadith(
      text: 'الْمُسْلِمُ مَنْ سَلِمَ الْمُسْلِمُونَ مِنْ لِسَانِهِ وَيَدِهِ',
      source: 'رواه البخاري',
    ),
    Hadith(
      text: 'تَبَسُّمُكَ فِي وَجْهِ أَخِيكَ لَكَ صَدَقَةٌ',
      source: 'رواه الترمذي',
    ),
  ];

  @override
  List<Hadith> all() => _hadiths;
}
