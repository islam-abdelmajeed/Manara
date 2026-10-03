import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manara/core/widgets/widgets.dart';
import 'package:manara/features/prayer/domain/entities/prayer_alerts.dart';
import 'package:manara/features/prayer/presentation/cubit/prayer_alerts_cubit.dart';
import 'package:manara/features/prayer/presentation/cubit/prayer_times_cubit.dart';
import 'package:manara/features/prayer/presentation/utils/alert_text.dart';

/// Fires the user's prayer alerts. Where the system schedules them
/// ([AlertNotifier.schedulesAhead], Android and iOS) it keeps that schedule
/// current and shows nothing itself. Otherwise, while the app is open: a
/// browser notification when allowed, else a message in the app. Expects
/// [PrayerTimesCubit] and [PrayerAlertsCubit] above it.
class PrayerAlertScheduler extends StatefulWidget {
  const PrayerAlertScheduler({
    required this.child,
    required this.notifier,
    this.messengerKey,
    this.clock = DateTime.now,
    super.key,
  });

  final Widget child;
  final AlertNotifier notifier;

  /// Where in-app alerts are shown.
  final GlobalKey<ScaffoldMessengerState>? messengerKey;

  final DateTime Function() clock;

  @override
  State<PrayerAlertScheduler> createState() => _PrayerAlertSchedulerState();
}

class _PrayerAlertSchedulerState extends State<PrayerAlertScheduler>
    with WidgetsBindingObserver {
  Timer? _timer;

  /// Alerts already shown, so a rebuild at the same moment can't repeat one.
  DateTime? _lastShown;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
      ..addObserver(this)
      ..addPostFrameCallback((_) => _schedule());
  }

  /// Back from the system settings, the permissions may have changed.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(context.read<PrayerAlertsCubit>().refreshPermission());
    }
  }

  void _schedule() {
    _timer?.cancel();
    if (!mounted) return;
    final prayer = context.read<PrayerTimesCubit>().state;
    final times = prayer.times;
    final alertsCubit = context.read<PrayerAlertsCubit>();
    final alerts = alertsCubit.state.settings;
    if (times == null) return;

    if (widget.notifier.schedulesAhead) {
      unawaited(alertsCubit.syncSystem(prayer.location, prayer.settings));
      // The system shows them, also while the app is open.
      if (alertsCubit.state.canNotify) return;
    }
    if (!alerts.anyEnabled) return;

    var after = widget.clock();
    final last = _lastShown;
    if (last != null && last.isAfter(after)) after = last;
    final event = AlertEvent.next(times, alerts, after);
    if (event == null) return;

    final wait = event.at.difference(widget.clock());
    _timer = Timer(wait.isNegative ? Duration.zero : wait, () => _fire(event));
  }

  void _fire(AlertEvent event) {
    if (!mounted) return;
    _lastShown = event.at;
    final (title, body) = alertText(event);
    final alerts = context.read<PrayerAlertsCubit>().state;
    if (alerts.canNotify) {
      widget.notifier.show(title, body);
    } else {
      final messenger =
          widget.messengerKey?.currentState ??
          ScaffoldMessenger.maybeOf(context);
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(appToastSnackBar('$title — $body'));
    }
    _schedule();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<PrayerTimesCubit, PrayerTimesState>(
          listenWhen: (a, b) => a.times != b.times,
          listener: (_, _) => _schedule(),
        ),
        BlocListener<PrayerAlertsCubit, PrayerAlertsState>(
          listenWhen: (a, b) =>
              a.settings != b.settings ||
              a.permission != b.permission ||
              a.exact != b.exact ||
              a.loaded != b.loaded,
          listener: (_, _) => _schedule(),
        ),
      ],
      child: widget.child,
    );
  }
}
