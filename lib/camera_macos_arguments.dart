import 'package:camera_macos/camera_macos_device.dart';
import 'package:flutter/material.dart';

enum PictureFormat{jpg,jpeg,tiff,bmp,png}

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
