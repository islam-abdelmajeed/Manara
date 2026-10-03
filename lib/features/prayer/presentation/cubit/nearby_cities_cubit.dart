import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:manara/features/prayer/domain/entities/prayer_location.dart';
import 'package:manara/features/prayer/domain/usecases/city_usecases.dart';

class NearbyCitiesState extends Equatable {
  const NearbyCitiesState({this.from, this.cities = const []});

  /// The location the [cities] are near.
  final PrayerLocation? from;
  final List<CityDistance> cities;

  @override
  List<Object?> get props => [from, cities];
}

/// The bundled cities nearest to the chosen location.
@injectable
class NearbyCitiesCubit extends Cubit<NearbyCitiesState> {
  NearbyCitiesCubit(this._getNearby) : super(const NearbyCitiesState());

  static const int count = 10;

  final GetNearbyCities _getNearby;
  int _requestId = 0;

  /// A no-op when [from] is already shown.
  Future<void> load(PrayerLocation from) async {
    if (from == state.from) return;
    final request = ++_requestId;
    final result = await _getNearby(NearbyCitiesParams(from, count: count));
    if (request != _requestId || isClosed) return;
    // A failed read leaves the list empty: the section just hides it.
    emit(NearbyCitiesState(from: from, cities: result.getOrElse((_) => [])));
  }
}
