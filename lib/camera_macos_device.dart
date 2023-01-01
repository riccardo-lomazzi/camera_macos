import 'package:camera_macos/extensions.dart';

class CameraMacOSDevice {
  String deviceId;
  String? manufacturer;
  CameraMacOSDeviceType deviceType;
  String? localizedName;

  CameraMacOSDevice({
    required this.deviceId,
    this.manufacturer,
    this.deviceType = CameraMacOSDeviceType.unknown,
    this.localizedName,
  });

  factory CameraMacOSDevice.fromMap(Map<String, dynamic> map) {
    return CameraMacOSDevice(
      deviceId: map['deviceId'] ?? '',
      manufacturer: map['manufacturer'],
      localizedName: map['localizedName'],
      deviceType: CameraMacOSDeviceType.values.safeElementAt(
              map["deviceType"] ?? CameraMacOSDeviceType.unknown.index) ??
          CameraMacOSDeviceType.unknown,
    );
  }
}

enum CameraMacOSDeviceType {
  video,
  audio,
  unknown,
}
