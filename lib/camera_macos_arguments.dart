import 'package:camera_macos/camera_macos_device.dart';
import 'package:flutter/material.dart';

class CameraMacOSArguments {
  /// The texture id.
  final int? textureId;

  /// Size of the texture.
  final Size size;

  /// Chosen device
  final List<CameraMacOSDevice>? devices;

  /// Create a [CameraMacOSArguments].
  CameraMacOSArguments({
    this.textureId,
    required this.size,
    this.devices,
  });
}
