
import 'camera_macos_platform_interface.dart';

class CameraMacos {
  Future<String?> getPlatformVersion() {
    return CameraMacosPlatform.instance.getPlatformVersion();
  }
}
