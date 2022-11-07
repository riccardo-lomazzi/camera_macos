import 'dart:typed_data';

import 'package:camera_macos/camera_macos_arguments.dart';
import 'package:camera_macos/camera_macos.dart';
import 'package:camera_macos/camera_macos_method_channel.dart';
import 'package:camera_macos/camera_macos_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockCameraMacOSPlatform
    with MockPlatformInterfaceMixin
    implements CameraMacOSPlatform {
  @override
  Future<CameraMacOSArguments?> initialize(
      {required CameraMacOSMode cameraMacOSMode}) {
    throw UnimplementedError();
  }

  @override
  Future<bool> startVideoRecording({double? maxVideoDuration}) {
    // TODO: implement recordVideo
    throw UnimplementedError();
  }

  @override
  Future<String?> stopVideoRecording() {
    // TODO: implement stopRecording
    throw UnimplementedError();
  }

  @override
  Future<Uint8List?> takePicture() {
    // TODO: implement takePicture
    throw UnimplementedError();
  }
}

void main() {
  final CameraMacOSPlatform initialPlatform = CameraMacOSPlatform.instance;

  test('$MethodChannelCameraMacOS is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelCameraMacOS>());
  });
}
