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
