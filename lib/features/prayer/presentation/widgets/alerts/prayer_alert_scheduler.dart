import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manara/core/widgets/widgets.dart';
import 'package:manara/features/prayer/domain/entities/prayer_alerts.dart';
import 'package:manara/features/prayer/presentation/cubit/prayer_alerts_cubit.dart';
import 'package:manara/features/prayer/presentation/cubit/prayer_times_cubit.dart';
import 'package:manara/features/prayer/presentation/utils/alert_text.dart';

/// Fires the user's prayer alerts while the app is open: a system
/// notification when the browser allows it, otherwise a message in the
/// app. Expects [PrayerTimesCubit] and [PrayerAlertsCubit] above it.
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

class _PrayerAlertSchedulerState extends State<PrayerAlertScheduler> {
  Timer? _timer;

  /// Alerts already shown, so a rebuild at the same moment can't repeat one.
  DateTime? _lastShown;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _schedule());
  }

  void _schedule() {
    _timer?.cancel();
    if (!mounted) return;
    final times = context.read<PrayerTimesCubit>().state.times;
    final alerts = context.read<PrayerAlertsCubit>().state.settings;
    if (times == null || !alerts.anyEnabled) return;

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
          listenWhen: (a, b) => a.settings != b.settings,
          listener: (_, _) => _schedule(),
        ),
      ],
      child: widget.child,
    );
  }
}
