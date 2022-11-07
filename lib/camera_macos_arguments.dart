import 'package:flutter/material.dart';

class CameraMacOSArguments {
  /// The texture id.
  final int? textureId;

  /// Size of the texture.
  final Size size;

  /// Create a [CameraMacOSArguments].
  CameraMacOSArguments({
    this.textureId,
    required this.size,
  });
}
