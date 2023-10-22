# Camera macOS

Implementation of ```AVKit``` camera for ```macOS```.
Can take pictures and record videos, even with external cameras.

## Getting Started

- [Basic usage](#basic-usage)
  - [Taking a picture](#taking-a-picture)
  - [Recording a video](#recording-a-video)
- [Limitations and notes](#limitations-and-notes)
- [Future Developments](#future-developments)
- [License](#license)

---

## Basic usage

Integrate ```CameraMacOSView``` in your widget tree.
You can choose a ```BoxFit``` method and a ```CameraMacOSMode``` (```photo``` or ```video```).
When the camera is initialized, a ```CameraMacOSController``` object is created and can be used to do basic things such as taking pictures and recording videos.

```
final GlobalKey cameraKey = GlobalKey("cameraKey");
late CameraMacOSController macOSController;

//... build method ...

CameraMacOSView(
    key: cameraKey,
    fit: BoxFit.fill,
    cameraMode: CameraMacOSMode.photo,
    onCameraInizialized: (CameraMacOSController controller) {
        setState(() {
            this.macOSController = controller;
        });
    },
),
```

### External cameras

The package supports external cameras too, not just the main Mac camera: you can specify an optional ```deviceId``` for the camera and an optional ```audioDeviceId``` for the microphone.
Both IDs are related to the ```uniqueID``` property of ```AVCaptureDevice```, and can be obtained with the ```listDevices``` method.

```
String? deviceId;
String? audioDeviceId;

// List devices

List<CameraMacOSDevice> videoDevices = await CameraMacOS.instance.listDevices({ deviceType: CameraMacOSMode.video });
List<CameraMacOSDevice> audioDevices = await CameraMacOS.instance.listDevices({ deviceType: CameraMacOSMode.audio });

// Set devices
deviceId = videoDevices.first.deviceId
audioDeviceId = audioDevices.first.deviceId

//... build method ...

CameraMacOSView(
    deviceId: deviceId, // optional camera parameter, defaults to the Mac primary camera
    audioDeviceId: audioDeviceId, // optional microphone parameter, defaults to the Mac primary microphone
    cameraMode: CameraMacOSMode.video,
    onCameraInizialized: (CameraMacOSController controller) {
        // ...
    },
),
```

A ```CameraMacOSDevice``` object contains the following properties (mapped to the original ```AVCaptureDevice``` class):
- ```deviceId```
- ```localizedName```
- ```manufacturer```
- ```deviceType``` (video or audio)

Once you've created a ```CameraMacOSView``` widget, you will be granted access to a ```CameraMacOSController``` object, which is your bridge to do the main two features, taking pictures and recording videos.
You also have information about the camera object you've just created with the ```CameraMacOSArguments``` property inside the controller.

### Set Focus Point of Camera ###

Setting the focus point can be done with the ```setFocusPoint``` method.

Note: the offset needs to be between 0 and 1.

``` dart
CameraMacOSFile? file = await macOSController.setFocusPoint(cameraId,Offset(0.5,0.5));


```

### Taking a picture ###

Taking pictures can be done with the ```takePicture``` method.

Note: for now, you cannot change the zoom or apply effects to the photos.

``` dart
CameraMacOSFile? file = await macOSController.takePicture();
if(file != null) {
    Uint8List? bytes = file.bytes;
    // do something with the file...
}

```

### Streaming an Image ###

Streaming an image can be done with the ```startImageStream``` method, and can be stopped with the ```stopImageStream```.

``` dart
CameraMacOSFile? file = await macOSController.startImageStream((CameraImageData imageData){
//place your code here
});

```

### Recording a video ###

Recording videos can be done with the ```recordVideo``` method, and can be stopped with the ```stopVideoRecording```.

``` dart
await macOSController.recordVideo(
    url: // get url from packages such as path_provider,
    maxVideoDuration: 30, // duration in seconds,
    onVideoRecordingFinished: (CameraMacOSFile? file, CameraMacOSException? exception) {
        // called when maxVideoDuration has been reached
        // do something with the file or catch the exception
    });
);

CameraMacOSFile? file = await macOSController.stopVideoRecording();

if(file != null) {
    Uint8List? bytes = file.bytes;
    // do something with the file...
}

```

#### Video settings ####

You can enable or disable audio recording with the ```enableAudio``` flag.

Default videos settings (currently locked) are:
- max resolution available to the selected camera
- default microphone format (```ac1```)
- default video format (```mp4```)

You can set a maximum video duration (in seconds) for recording videos with ```maxVideoDuration```.
A native timer will fire after time has passed, and will call the ```onVideoRecordingFinished``` method.

You can also set a saved video file location. Default is in the ```Library/Cache``` directory of the application.

Audio recording can be enabled or disabled with the ```enableAudio``` flag both in the camera initialization phase or within the ```recordVideo``` method (default ```true```).

### Output ###
After a video or a picture is taken, a ```CameraMacOSFile``` object is generated, containing the ```bytes``` of the content. If you specify a ```url``` save destination for a video, it will return back the file path too.

### Widget refreshing ###
- If you change the widget ```Key```, ```deviceId```  or the ```CameraMacOsMode```, the widget will reinitialize.

## Limitations and notes

- The package supports ```macOS 10.11``` and onwards.
- The plugin is just a temporary substitutive package for the official Flutter team's ```camera``` package. It will work only on ```macOS```.
- Zoom and orientation change are currently unsupported

## Future developments
- Being able to change the audio quality
- Zoom and orientation change

## License

[MIT](https://github.com/riccardo-lomazzi/webview_macos/blob/main/LICENSE)

