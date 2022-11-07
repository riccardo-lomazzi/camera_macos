import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:camera_macos/camera_macos_method_channel.dart';

void main() {
  MethodChannelCameraMacOS platform = MethodChannelCameraMacOS();
  const MethodChannel channel = MethodChannel('camera_macos');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });
}
