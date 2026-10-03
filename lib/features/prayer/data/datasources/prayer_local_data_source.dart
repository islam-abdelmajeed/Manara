import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:manara/features/prayer/data/models/prayer_month_model.dart';
import 'package:manara/features/prayer/domain/entities/prayer_alerts.dart';
import 'package:manara/features/prayer/domain/entities/prayer_location.dart';
import 'package:manara/features/prayer/domain/entities/prayer_settings.dart';
import 'package:manara/features/prayer/domain/entities/prayer_times.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class PrayerLocalDataSource {
  /// `null` until a city is saved, or when the stored value is unreadable.
  PrayerLocation? readLocation();

  Future<void> writeLocation(PrayerLocation location);

  /// Defaults for anything missing or out of range.
  PrayerSettings readSettings();

  Future<void> writeSettings(PrayerSettings settings);

  /// Everything off when nothing (readable) is stored.
  AlertSettings readAlerts();

  Future<void> writeAlerts(AlertSettings alerts);

  /// A cached month with its [PrayerMonth.fetchedAt], or `null`.
  PrayerMonth? readMonth(String key);

  /// Caches [month] (which must carry its `fetchedAt`), keeping only the
  /// [maxMonths] most recently written.
  Future<void> writeMonth(String key, PrayerMonth month);
}

@LazySingleton(as: PrayerLocalDataSource)
class PrayerLocalDataSourceImpl implements PrayerLocalDataSource {
  const PrayerLocalDataSourceImpl(this._prefs);

  final SharedPreferences _prefs;

  static const int maxMonths = 6;

  static const _location = 'prayer.location';
  static const _settings = 'prayer.settings';
  static const _alerts = 'prayer.alerts';
  static const _months = 'prayer.months';
  static const _monthPrefix = 'prayer.month.';

  @override
  PrayerLocation? readLocation() {
    final json = _decode(_prefs.getString(_location));
    if (json == null) return null;
    try {
      return PrayerLocation(
        id: json['id'] as int,
        name: json['name'] as String,
        nameEn: json['nameEn'] as String,
        country: json['country'] as String,
        countryCode: json['countryCode'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        timeZone: json['timeZone'] as String,
      );
    } on TypeError {
      return null;
    }
  }

  @override
  Future<void> writeLocation(PrayerLocation l) async {
    await _prefs.setString(
      _location,
      jsonEncode({
        'id': l.id,
        'name': l.name,
        'nameEn': l.nameEn,
        'country': l.country,
        'countryCode': l.countryCode,
        'latitude': l.latitude,
        'longitude': l.longitude,
        'timeZone': l.timeZone,
      }),
    );
  }

  // Enums are stored by name so reordering them never changes a choice.
  @override
  PrayerSettings readSettings() {
    const defaults = PrayerSettings();
    final json = _decode(_prefs.getString(_settings));
    if (json == null) return defaults;

    T byName<T extends Enum>(List<T> values, Object? name, T fallback) {
      for (final v in values) {
        if (v.name == name) return v;
      }
      return fallback;
    }

    int clamp(Object? value, int max) =>
        value is int ? value.clamp(-max, max) : 0;

    final tune = json['tune'];
    return PrayerSettings(
      method: json['method'] is int ? json['method'] as int : defaults.method,
      school: byName(AsrSchool.values, json['school'], defaults.school),
      highLatitudeRule: byName(
        HighLatitudeRule.values,
        json['highLatitudeRule'],
        defaults.highLatitudeRule,
      ),
      hijriOffset: clamp(json['hijriOffset'], PrayerSettings.maxHijriOffset),
      tune: {
        if (tune is Map<String, dynamic>)
          for (final p in Prayer.values)
            if (clamp(tune[p.name], PrayerSettings.maxTune) case final m
                when m != 0)
              p: m,
      },
    );
  }

  @override
  Future<void> writeSettings(PrayerSettings s) async {
    await _prefs.setString(
      _settings,
      jsonEncode({
        'method': s.method,
        'school': s.school.name,
        'highLatitudeRule': s.highLatitudeRule.name,
        'hijriOffset': s.hijriOffset,
        'tune': {for (final e in s.tune.entries) e.key.name: e.value},
      }),
    );
  }

  @override
  AlertSettings readAlerts() {
    final json = _decode(_prefs.getString(_alerts));
    if (json == null) return const AlertSettings();
    final prayers = json['prayers'];
    return AlertSettings(
      suhoor: json['suhoor'] == true,
      friday: json['friday'] == true,
      prayers: {
        if (prayers is Map<String, dynamic>)
          for (final p in Prayer.values.where((p) => p.isPrayer))
            if (prayers[p.name] case final Map<String, dynamic> a)
              p: PrayerAlert(
                enabled: a['enabled'] == true,
                minutesBefore:
                    PrayerAlert.beforeChoices.contains(a['minutesBefore'])
                    ? a['minutesBefore'] as int
                    : 0,
              ),
      },
    );
  }

  @override
  Future<void> writeAlerts(AlertSettings alerts) async {
    await _prefs.setString(
      _alerts,
      jsonEncode({
        'suhoor': alerts.suhoor,
        'friday': alerts.friday,
        'prayers': {
          for (final e in alerts.prayers.entries)
            e.key.name: {
              'enabled': e.value.enabled,
              'minutesBefore': e.value.minutesBefore,
            },
        },
      }),
    );
  }

  @override
  PrayerMonth? readMonth(String key) {
    final json = _decode(_prefs.getString('$_monthPrefix$key'));
    if (json == null) return null;
    final fetchedAt = DateTime.tryParse(json['fetchedAt'] as String? ?? '');
    final month = json['month'];
    if (fetchedAt == null || month is! Map<String, dynamic>) return null;
    try {
      return PrayerMonthModel.fromJson(month, fetchedAt: fetchedAt);
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  @override
  Future<void> writeMonth(String key, PrayerMonth month) async {
    await _prefs.setString(
      '$_monthPrefix$key',
      jsonEncode({
        'fetchedAt': month.fetchedAt!.toUtc().toIso8601String(),
        'month': PrayerMonthModel.toJson(month),
      }),
    );
    final keys = [
      key,
      ...(_prefs.getStringList(_months) ?? const <String>[]).where(
        (k) => k != key,
      ),
    ];
    await Future.wait([
      for (final old in keys.skip(maxMonths))
        _prefs.remove('$_monthPrefix$old'),
      _prefs.setStringList(_months, keys.take(maxMonths).toList()),
    ]);
  }

  static Map<String, dynamic>? _decode(String? raw) {
    if (raw == null) return null;
    try {
      final value = jsonDecode(raw);
      return value is Map<String, dynamic> ? value : null;
    } on FormatException {
      return null;
    }
  }
}
