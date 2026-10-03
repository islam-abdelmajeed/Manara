import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manara/core/theme/theme.dart';
import 'package:manara/core/widgets/widgets.dart';
import 'package:manara/features/prayer/presentation/cubit/device_location_cubit.dart';
import 'package:manara/features/prayer/presentation/cubit/prayer_times_cubit.dart';

/// "استخدم موقعي": locates the device and makes it the prayer location.
/// Expects [DeviceLocationCubit] and [PrayerTimesCubit] above it; only one
/// should be on screen, as it applies the result.
class UseMyLocationButton extends StatelessWidget {
  const UseMyLocationButton({this.expand = false, super.key});

  /// Full width, with a link to the settings under it when only they can
  /// help (permission blocked, location off).
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DeviceLocationCubit>().state;
    final button = AppButton.secondary(
      label: 'استخدم موقعي',
      icon: AppIcons.markerPin,
      isLoading: state.locating,
      onPressed: context.read<DeviceLocationCubit>().locate,
      expand: expand,
    );

    return BlocListener<DeviceLocationCubit, DeviceLocationState>(
      listenWhen: (a, b) => a.status != b.status,
      listener: (context, state) {
        if (state.location case final location?) {
          showAppToast(context, 'تم تحديد موقعك: ${location.name}');
          context.read<PrayerTimesCubit>().changeLocation(location);
        } else if (state.failure case final failure?) {
          showAppToast(context, failure.message);
        }
      },
      child: !expand
          ? button
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                button,
                if (state.needsSettings)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(
                      onPressed: context
                          .read<DeviceLocationCubit>()
                          .openSettings,
                      child: Text(
                        'فتح إعدادات الجهاز',
                        style: AppTypography.captionBold.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
