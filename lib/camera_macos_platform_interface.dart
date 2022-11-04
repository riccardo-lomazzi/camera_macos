import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'camera_macos_method_channel.dart';

abstract class CameraMacosPlatform extends PlatformInterface {
  /// Constructs a CameraMacosPlatform.
  CameraMacosPlatform() : super(token: _token);

  static final Object _token = Object();

  static CameraMacosPlatform _instance = MethodChannelCameraMacos();

  /// The default instance of [CameraMacosPlatform] to use.
  ///
  /// Defaults to [MethodChannelCameraMacos].
  static CameraMacosPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [CameraMacosPlatform] when
  /// they register themselves.
  static set instance(CameraMacosPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
