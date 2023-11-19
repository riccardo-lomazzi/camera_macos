## 0.0.8
* Bug Fixes: Fixed issue with startimagestream on macos 14.0
* Added ability to turn light on or off
* Added ability to change camera orientation
* Added ability to zoom on imageStream
* Added ability to change audio quality
* Added ability to chande audio codec
* Removed deviceId requirment from setFocusPoint
## 0.0.7+2
* Updated README.md
## 0.0.7+1
* Updated README.md
## 0.0.7
* Added ability to change the video and camera output resolution.
* Added ability to change the file format for camera output.
* Added ability to change the file format for video output.
* Added image streaming
## 0.0.6+5
* Fixed error reporting while initializing camera
## 0.0.6+4
* Fixed a concurrency bug that could randomly prevent the AVAssetWriter from writing into the buffer and fail the recording
* Updated docs
## 0.0.6+3
* Fixed a concurrency bug that could prevent the AVAssetWriter session to start
* Fixed a bug that could prevent the video from being created in the destination folder
## 0.0.6+2
* Small fix for handling ```nil``` ```textureId``` values.
## 0.0.6+1
* Updated README
## 0.0.6
* Added support for external cameras (see Readme for info about ```listDevices``` method)
* Various recording crashes fixes

## 0.0.5
* Added tests

## 0.0.4
* Added ```destroy``` method

## 0.0.3
* Fixed ```CameraMacOSFile``` wrong casting

## 0.0.2
* Switched to ```AVCameraVideoDataOutput```

## 0.0.1
* Created plugin
