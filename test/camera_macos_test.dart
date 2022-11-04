import 'package:flutter_test/flutter_test.dart';
import 'package:camera_macos/camera_macos.dart';
import 'package:camera_macos/camera_macos_platform_interface.dart';
import 'package:camera_macos/camera_macos_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockCameraMacosPlatform
    with MockPlatformInterfaceMixin
    implements CameraMacosPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final CameraMacosPlatform initialPlatform = CameraMacosPlatform.instance;

  test('$MethodChannelCameraMacos is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelCameraMacos>());
  });

  test('getPlatformVersion', () async {
    CameraMacos cameraMacosPlugin = CameraMacos();
    MockCameraMacosPlatform fakePlatform = MockCameraMacosPlatform();
    CameraMacosPlatform.instance = fakePlatform;

    expect(await cameraMacosPlugin.getPlatformVersion(), '42');
  });
}
