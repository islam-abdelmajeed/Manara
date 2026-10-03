import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:manara/features/prayer/domain/entities/prayer_location.dart';
import 'package:manara/features/prayer/domain/usecases/city_usecases.dart';

class CitySearchState extends Equatable {
  const CitySearchState({
    this.query = '',
    this.countryCode,
    this.listAll = false,
    this.results = const [],
  });

  final String query;

  /// Limits the results to one country (from "مدن مصر").
  final String? countryCode;

  /// Lists every city (or every city of [countryCode]) with no query.
  final bool listAll;

  final List<PrayerLocation> results;

  /// Whether a list should be shown at all.
  bool get isOpen => listAll || query.trim().isNotEmpty;

  @override
  List<Object?> get props => [query, countryCode, listAll, results];
}

/// Searches the bundled city list for the settings screen.
@injectable
class CitySearchCubit extends Cubit<CitySearchState> {
  CitySearchCubit(this._search) : super(const CitySearchState());

  final SearchCities _search;
  int _requestId = 0;

  /// Opens the full list, of one country when [countryCode] is given.
  Future<void> browse({String? countryCode}) =>
      _run(state.query, countryCode: countryCode, listAll: true);

  Future<void> search(String query) =>
      _run(query, countryCode: state.countryCode, listAll: state.listAll);

  /// Back to an empty field and no list.
  void clear() {
    _requestId++;
    emit(const CitySearchState());
  }

  Future<void> _run(
    String query, {
    required String? countryCode,
    required bool listAll,
  }) async {
    final request = ++_requestId;
    if (!listAll && query.trim().isEmpty) {
      emit(CitySearchState(query: query, countryCode: countryCode));
      return;
    }
    final result = await _search(
      SearchCitiesParams(query, countryCode: countryCode),
    );
    if (request != _requestId || isClosed) return;
    emit(
      CitySearchState(
        query: query,
        countryCode: countryCode,
        listAll: listAll,
        results: result.getOrElse((_) => const []),
      ),
    );
  }
}
