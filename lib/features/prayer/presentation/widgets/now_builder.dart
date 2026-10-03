import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manara/features/prayer/presentation/cubit/prayer_times_cubit.dart';

/// Rebuilds every second with the current time, and asks the
/// [PrayerTimesCubit] to load the new day once the shown one is over (its
/// own midnight timer can be held up while the app is in the background).
class NowBuilder extends StatefulWidget {
  const NowBuilder({required this.builder, required this.clock, super.key});

  final Widget Function(BuildContext context, DateTime now) builder;
  final DateTime Function() clock;

  @override
  State<NowBuilder> createState() => _NowBuilderState();
}

class _NowBuilderState extends State<NowBuilder> {
  Timer? _ticker;
  late DateTime _now = widget.clock();

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = widget.clock());
      final cubit = context.read<PrayerTimesCubit>();
      final times = cubit.state.times;
      if (times != null && !_now.isBefore(times.tomorrow.start)) {
        unawaited(cubit.refreshIfStale());
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _now);
}
