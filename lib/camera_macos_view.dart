import 'package:camera_macos/camera_macos_arguments.dart';
import 'package:camera_macos/camera_macos_controller.dart';
import 'package:camera_macos/camera_macos_method_channel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'camera_macos_platform_interface.dart';

class CameraMacOSView extends StatefulWidget {
  /// Handles how the widget should fit the screen.
  final BoxFit fit;

  /// DeviceId of the video streaming device
  final String? deviceId;

  /// Audio DeviceId of the audio streaming device
  final String? audioDeviceId;

  /// Enable audio while recording video. Defaults to 'true'. You can always override this setting when calling the 'startRecording' method.
  final bool enableAudio;

  /// Choose between audio or video mode
  final CameraMacOSMode cameraMode;

  /// Callback that gets called while the "initialize" method hasn't returned a value yet.
  final Widget Function(Object?)? onCameraLoading;

  /// Callback that gets called when the "initialize" method has returned a value.
  final Function(CameraMacOSController) onCameraInizialized;

  /// Callback that gets called when the "destroy" method has returned.
  final Widget Function()? onCameraDestroyed;

  /// [EXPERIMENTAL][NOT WORKING] It won't work until Flutter will officially support macOS Platform Views.
  final bool usePlatformView;

  /// Format of the output photo
  final PictureFormat pictureFormat;

  /// Format of the output video
  final VideoFormat videoFormat;

  /// Resolution of the output video/image
  final PictureResolution resolution;

  /// Format of the audion the video
  final AudioFormat audioFormat;

  /// Quality of the output audio
  final AudioQuality audioQuality;

  /// Turn the light on the device on
  final Torch toggleTorch;

  /// The Orientation of the camera
  final CameraOrientation orientation;

  const CameraMacOSView({
    Key? key,
    this.deviceId,
    this.audioDeviceId,
    this.enableAudio = true,
    this.fit = BoxFit.contain,
    required this.cameraMode,
    required this.onCameraInizialized,
    this.onCameraLoading,
    this.onCameraDestroyed,
    this.usePlatformView = false,
    this.resolution = PictureResolution.max,
    this.audioQuality = AudioQuality.max,
    this.pictureFormat = PictureFormat.tiff,
    this.videoFormat = VideoFormat.mp4,
    this.audioFormat = AudioFormat.kAudioFormatAppleLossless,
    this.toggleTorch = Torch.off,
    this.orientation = CameraOrientation.orientation0deg,
  }) : super(key: key);

  @override
  CameraMacOSViewState createState() => CameraMacOSViewState();
}

class CameraMacOSViewState extends State<CameraMacOSView> {
  late CameraMacOSArguments arguments;
  late Future<CameraMacOSArguments?> initializeCameraFuture;

  @override
  void initState() {
    super.initState();
    initializeCameraFuture = CameraMacOSPlatform.instance
        .initialize(
            deviceId: widget.deviceId,
            audioDeviceId: widget.audioDeviceId,
            cameraMacOSMode: widget.cameraMode,
            enableAudio: widget.enableAudio,
            resolution: widget.resolution,
            audioQuality: widget.audioQuality,
            videoFormat: widget.videoFormat,
            audioFormat: widget.audioFormat,
            pictureFormat: widget.pictureFormat,
            toggleTorch: widget.toggleTorch,
            orientation: widget.orientation)
        .then((value) {
      if (value != null) {
        this.arguments = value;
        widget.onCameraInizialized(
          CameraMacOSController(value),
        );
      }
      return value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: initializeCameraFuture,
      builder: (BuildContext context,
          AsyncSnapshot<CameraMacOSArguments?> snapshot) {
        if (snapshot.hasError) {
          if (widget.onCameraLoading != null) {
            return widget.onCameraLoading!(snapshot.error);
          } else {
            return const ColoredBox(color: Colors.black);
          }
        }
        if (!snapshot.hasData) {
          if (widget.onCameraLoading != null) {
            return widget.onCameraLoading!(null);
          } else {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        }

        if (snapshot.data != null && snapshot.data!.textureId == null) {
          return Container();
        }

        if (CameraMacOSPlatform.instance is MethodChannelCameraMacOS &&
            (CameraMacOSPlatform.instance as MethodChannelCameraMacOS)
                .isDestroyed) {
          if (widget.onCameraDestroyed != null) {
            return widget.onCameraDestroyed!();
          } else {
            return Container();
          }
        }

        double cameraWidth = snapshot.data!.size.width;
        double cameraHeight = snapshot.data!.size.height;

        final Map<String, dynamic> creationParams = <String, dynamic>{
          "width": cameraWidth,
          "height": cameraHeight,
        };
        return ClipRect(
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: FittedBox(
              fit: widget.fit,
              child: SizedBox(
                width: cameraWidth,
                height: cameraHeight,
                child: GestureDetector(
                  onTapUp: (details) => setFocusPoint(
                    details,
                    cameraWidth,
                    cameraHeight,
                  ),
                  child: widget.usePlatformView
                      ? UiKitView(
                          viewType: "camera_macos_view",
                          onPlatformViewCreated: (id) {
                            print(id);
                          },
                          creationParams: creationParams,
                          creationParamsCodec: const StandardMessageCodec(),
                        )
                      : Texture(
                          textureId: snapshot.data!.textureId!,
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void didUpdateWidget(CameraMacOSView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // if camera mode has changed mode, reinitialize the camera
    if (oldWidget.deviceId != widget.deviceId ||
        oldWidget.audioDeviceId != widget.audioDeviceId ||
        oldWidget.cameraMode != widget.cameraMode ||
        oldWidget.enableAudio != widget.enableAudio ||
        oldWidget.toggleTorch != widget.toggleTorch ||
        oldWidget.resolution != widget.resolution ||
        oldWidget.audioQuality != widget.audioQuality ||
        oldWidget.videoFormat != widget.videoFormat ||
        oldWidget.audioFormat != widget.audioFormat ||
        oldWidget.pictureFormat != widget.pictureFormat ||
        oldWidget.usePlatformView != widget.usePlatformView ||
        oldWidget.orientation != widget.orientation ||
        oldWidget.videoFormat != widget.videoFormat ||
        oldWidget.key != widget.key) {
      initializeCameraFuture = CameraMacOSPlatform.instance
          .initialize(
        deviceId: widget.deviceId,
        audioDeviceId: widget.audioDeviceId,
        cameraMacOSMode: widget.cameraMode,
        enableAudio: widget.enableAudio,
        resolution: widget.resolution,
        audioQuality: widget.audioQuality,
        pictureFormat: widget.pictureFormat,
        videoFormat: widget.videoFormat,
        audioFormat: widget.audioFormat,
        toggleTorch: widget.toggleTorch,
        orientation: widget.orientation,
      )
          .then((value) {
        if (value != null) {
          this.arguments = value;
          widget.onCameraInizialized(
            CameraMacOSController(value),
          );
        }
        return value;
      });
    }
  }

  void setFocusPoint(TapUpDetails details, double maxWidth, double maxHeight) {
    Offset newPoint = Offset(
      details.localPosition.dx / maxWidth,
      details.localPosition.dy / maxHeight,
    );
    CameraMacOS.instance.setFocusPoint(newPoint);
  }

  @override
  void dispose() {
    super.dispose();
  }
}
