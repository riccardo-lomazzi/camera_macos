import 'package:camera_macos/camera_macos_view.dart';

class CameraMacOSDevice {
  String deviceId;
  List<CameraMacOSMode> supportedModes;

  CameraMacOSDevice({
    required this.deviceId,
    required this.supportedModes,
  });
}
