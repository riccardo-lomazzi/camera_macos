import Cocoa
import FlutterMacOS
import AVFoundation

public class CameraMacosPlugin: NSObject, FlutterPlugin, FlutterTexture, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate, AVAssetWriterDelegate, AVCaptureFileOutputRecordingDelegate,
    FlutterStreamHandler{
    
    let registry: FlutterTextureRegistry
    let outputChannel: FlutterMethodChannel!
    var sink: FlutterEventSink!
    
    // Texture id of the camera preview
    var textureId: Int64!
    
    // Capture session of the camera
    var captureSession: AVCaptureSession!
    
    // The selected camera
    var videoDevice: AVCaptureDevice!
    
    // The selected microphone
    var audioDevice: AVCaptureDevice?
    
    // Image to be sent to the texture
    var latestBuffer: CVImageBuffer!
    
    // The asset writer to write a file on disk
    var videoWriter: AVAssetWriter!
    
    // Temp variabile to store FlutterResult methods
    var videoOutputFileURL: URL!
    
    // Enable Audio
    var enableAudio: Bool = true
    
    // Video quality
    var videoOutputWidth: Int32!
    var videoOutputHeight: Int32!
    
    // Semaphore variable
    var isTakingPicture: Bool = false
    var isRecording: Bool = false
    var i: Int = 0
    var videoOutputQueue: DispatchQueue!
    var isDestroyed = false
    
    // Alternate Movie File Output
    var cameraView: NSView!
    var useMovieFileOutput: Bool!
    var savedResult: FlutterResult!
    var factory: CameraMacOSNativeFactory!
    var previewLayer: AVCaptureVideoPreviewLayer!

    var pictureFormat:NSBitmapImageRep.FileType = NSBitmapImageRep.FileType.tiff
    var videoFormat:AVFileType = AVFileType.mp4
    var vstring:String = "mp4"
    var resSize:NSSize? = nil
    var settingsAssistant:AVOutputSettingsAssistant? = nil
    
    init(_ registry: FlutterTextureRegistry, _ outputChannel: FlutterMethodChannel) {
        self.registry = registry
        self.outputChannel = outputChannel
        super.init()
    }
    // FlutterStreamHandler
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        sink = events
        return nil
    }
    
    // FlutterStreamHandler
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        sink = nil
        return nil
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let inputChannel = FlutterMethodChannel(name: "camera_macos", binaryMessenger: registrar.messenger)
        let outputChannel = FlutterMethodChannel(name: "camera_macos", binaryMessenger: registrar.messenger)
        let instance = CameraMacosPlugin(registrar.textures, outputChannel)
        registrar.addMethodCallDelegate(instance, channel: inputChannel)
        let factory = CameraMacOSNativeFactory(messenger: registrar.messenger)
        registrar.register(factory, withId: "camera_macos_view")
        instance.factory = factory
        
        // Channel for communicating with platform plugins using event streams
        let event = FlutterEventChannel(name:"camera_macos/stream", binaryMessenger: registrar.messenger)
        registrar.addMethodCallDelegate(instance, channel: outputChannel)
        event.setStreamHandler(instance)
    }
    
    public func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
        if latestBuffer == nil {
            return nil
        }
        if self.sink != nil{
            let u = imageFromSampleBuffer(imageBuffer: latestBuffer)!
            let bytesPerRow = u.bytesPerRow
            let width = Int(u.size.width)
            let height = Int(u.size.height)
            
            let newData:Data = Data(bytes: u.bitmapData!, count: Int(bytesPerRow*height))
            
            self.sink([
                "width": width,
                "height": height,
                "data": newData,
            ]);
        }
        return Unmanaged<CVPixelBuffer>.passRetained(latestBuffer)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "listDevices":
            let arguments = call.arguments as? Dictionary<String, Any> ?? [:]
            listDevices(arguments, result)
        case "initialize":
            guard let arguments = call.arguments as? Dictionary<String, Any>
            else {
                result(FlutterError(code: "INVALID_ARGS", message: "", details: nil).toMap)
                return
            }
            initCamera(arguments, result)
        case "takePicture":
            takePicture(result,pictureFormat)
        case "startRecording":
            let arguments = call.arguments as? Dictionary<String, Any> ?? [:]
            startRecording(arguments, result)
        case "stopRecording":
            stopRecording(result)
        case "destroy":
            destroy(result)
        case "setFocusPoint":
            guard let arguments = call.arguments as? Dictionary<String, Any>
            else {
                result(FlutterError(code: "INVALID_ARGS", message: "", details: nil).toMap)
                return
            }
            setFocusPoint(arguments, result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    func setFocusPoint(_ arguments: Dictionary<String, Any>, _ result: @escaping FlutterResult) {
        var capturedVideoDevices: [AVCaptureDevice] = []
        
        if #available(macOS 10.15, *) {
            capturedVideoDevices = AVCaptureDevice.captureDevices(deviceTypes: [.builtInWideAngleCamera, .externalUnknown], mediaType: .video)
        } else {
            capturedVideoDevices = AVCaptureDevice.captureDevices(mediaType: .video)
        }

        let deviceId = arguments["deviceId"] as? String;
        if let newCameraObject = capturedVideoDevices.first(where: { $0.uniqueID == deviceId }) {
            let x = arguments["x"] as! Double;
            let y = arguments["y"] as! Double;

            let focusPoint: CGPoint = .init(x: x, y: y)
            if newCameraObject.isFocusPointOfInterestSupported {
                newCameraObject.focusPointOfInterest = focusPoint
            }
        }
    }

    func requestPermission(completionHandler: @escaping (Bool) -> Void) {
        if #available(macOS 10.14, *) {
            AVCaptureDevice.requestAccess(for: .video, completionHandler: completionHandler)
        } else {
            completionHandler(false)
        }
    }
    
    func generateVideoFileURL(randomGUID: Bool = false) -> URL {
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        var fileUrl = paths[0].appendingPathComponent("output."+vstring)
        if randomGUID {
            fileUrl = paths[0].appendingPathComponent(UUID().uuidString + "."+vstring)
        }
        return fileUrl
    }
    
    func listDevices(_ arguments: Dictionary<String, Any>, _ result: @escaping FlutterResult) {
        self.requestPermission { granted in
            if granted {
                var mediaType: AVMediaType = .video
                if let deviceType = arguments["deviceType"] as? Int {
                    switch(deviceType) {
                    case 0: // video
                        mediaType = .video
                    case 1: // audio
                        mediaType = .audio
                    default:
                        break
                    }
                }
                let devices: [AVCaptureDevice] = AVCaptureDevice.captureDevices(mediaType: mediaType)
                var devicesList: [Dictionary<String, Any>] = []
                for device in devices {
                    devicesList.append([
                        "deviceType": mediaType == .video ? 0 : 1,
                        "localizedName" : device.localizedName,
                        "manufacturer": device.manufacturer,
                        "deviceId": device.uniqueID
                    ])
                }
                result([
                    "devices": devicesList,
                ])
            } else {
                result(FlutterError(code: "CAMERA_INITIALIZATION_ERROR", message: "Permission not granted", details: nil).toFlutterResult)
            }
        }
    }

    func initCamera(_ arguments: Dictionary<String, Any>, _ result: @escaping FlutterResult) {
        if let captureSession = self.captureSession, captureSession.isRunning {
            captureSession.stopRunning()
        }
        self.requestPermission { granted in
            if granted {
                self.isDestroyed = false
                self.textureId = self.registry.register(self)
                self.captureSession = AVCaptureSession()
                self.captureSession.beginConfiguration()
                var sessionPresetSet: Bool = false
                if let sessionPresetArg = arguments["type"] as? Int {
                    switch(sessionPresetArg) {
                    case 0:
                        if self.captureSession.canSetSessionPreset(.photo) {
                            sessionPresetSet = true
                            self.captureSession.sessionPreset = .photo
                        }
                    case 1:
                        if self.captureSession.canSetSessionPreset(.high) {
                            sessionPresetSet = true
                            self.captureSession.sessionPreset = .high
                        }
                    default:
                        if self.captureSession.canSetSessionPreset(.photo) {
                            sessionPresetSet = true
                            self.captureSession.sessionPreset = .photo
                        }
                    }
                }
                
                guard sessionPresetSet else {
                    result(FlutterError(code: "CAMERA_INITIALIZATION_ERROR", message: "Could not set sessionPreset for this device", details: nil).toFlutterResult)
                    return
                }
                
                var newCameraObject: AVCaptureDevice!
                var capturedVideoDevices: [AVCaptureDevice] = []
                
                if #available(macOS 10.15, *) {
                    capturedVideoDevices = AVCaptureDevice.captureDevices(deviceTypes: [.builtInWideAngleCamera, .externalUnknown], mediaType: .video)
                } else {
                    capturedVideoDevices = AVCaptureDevice.captureDevices(mediaType: .video)
                }
                
                if let deviceId: String = arguments["deviceId"] as? String, !deviceId.isEmpty {
                    newCameraObject = capturedVideoDevices.first(where: { $0.uniqueID == deviceId })
                } else {
                    newCameraObject = capturedVideoDevices.first
                }
                
                switch arguments["pformat"] as! String{
                    case "jpg":
                        self.pictureFormat = NSBitmapImageRep.FileType.jpeg
                        break
                    case "jepg":
                        self.pictureFormat = NSBitmapImageRep.FileType.jpeg2000
                        break
                    case "bmp":
                        self.pictureFormat = NSBitmapImageRep.FileType.bmp
                        break
                    case "png":
                        self.pictureFormat = NSBitmapImageRep.FileType.png
                        break
                    default:
                        self.pictureFormat = NSBitmapImageRep.FileType.tiff
                        break
                }
                switch arguments["vformat"] as! String{
                    case "m4v":
                        self.videoFormat = AVFileType.m4v
                        self.vstring = "m4v"
                        break
                    case "mov":
                        self.videoFormat = AVFileType.mov
                        self.vstring = "mov"
                        break
                    default:
                        self.videoFormat = AVFileType.mp4
                        self.vstring = "mp4"
                        break
                }
                switch arguments["resolution"] as! String{
                    case "low":
                        self.resSize = NSMakeSize(CGFloat(640), CGFloat(480))
                        self.settingsAssistant = AVOutputSettingsAssistant(preset: .preset640x480)
                        break
                    case "medium":
                        self.resSize = NSMakeSize(CGFloat(960), CGFloat(540))
                        self.settingsAssistant = AVOutputSettingsAssistant(preset: .preset960x540)
                        break
                    case "high":
                        self.resSize = NSMakeSize(CGFloat(1280), CGFloat(720))
                        self.settingsAssistant = AVOutputSettingsAssistant(preset: .preset1280x720)
                        break
                    case "veryHigh":
                        self.resSize = NSMakeSize(CGFloat(1920), CGFloat(1080))
                        self.settingsAssistant = AVOutputSettingsAssistant(preset: .preset1920x1080)
                        break
                    case "ultraHigh":
                        self.resSize = NSMakeSize(CGFloat(3840), CGFloat(2160))
                        self.settingsAssistant = AVOutputSettingsAssistant(preset: .preset3840x2160)
                        break
                    default:
                        self.resSize = nil
                        self.settingsAssistant = AVOutputSettingsAssistant(preset: .preset1280x720)
                        break
                }
                
                guard let newCameraObject: AVCaptureDevice = newCameraObject else {
                    result(FlutterError(code: "CAMERA_INITIALIZATION_ERROR", message: "Could not find a suitable camera on this device", details: nil).toFlutterResult)
                    return
                }
                self.videoDevice = newCameraObject
                do {
                    let focusPoint: CGPoint = .init(x: 0.5, y: 0.5)
                    try newCameraObject.lockForConfiguration()
                    if newCameraObject.isFocusModeSupported(.autoFocus) {
                        newCameraObject.focusMode = .autoFocus
                    }
                    if newCameraObject.isFocusPointOfInterestSupported {
                        newCameraObject.focusPointOfInterest = focusPoint
                    }
                    if newCameraObject.isExposureModeSupported(.continuousAutoExposure) {
                        newCameraObject.exposureMode = AVCaptureDevice.ExposureMode.continuousAutoExposure
                    }
                    if newCameraObject.isExposurePointOfInterestSupported {
                        newCameraObject.exposurePointOfInterest = focusPoint
                    }
                    newCameraObject.unlockForConfiguration()
                    
                    let videoInput = try AVCaptureDeviceInput(device: newCameraObject)
                    
                    if self.captureSession.canAddInput(videoInput) {
                        self.captureSession.addInput(videoInput)
                    }
                    
                    let shouldRecordAudio = arguments["enableAudio"] as? Bool ?? true
                    self.enableAudio = shouldRecordAudio
                    
                    if shouldRecordAudio {
                        var capturedAudioDevices: [AVCaptureDevice] = []
                        
                        if #available(macOS 10.15, *) {
                            capturedAudioDevices = AVCaptureDevice.captureDevices(deviceTypes: [.builtInMicrophone, .externalUnknown], mediaType: .audio)
                        } else {
                            capturedAudioDevices = AVCaptureDevice.captureDevices(mediaType: .audio)
                        }
                        
                        var micObject: AVCaptureDevice!
                        if let audioDeviceId: String = arguments["audioDeviceId"] as? String, !audioDeviceId.isEmpty {
                            micObject = capturedAudioDevices.first(where: { $0.uniqueID == audioDeviceId })
                        } else {
                            micObject = AVCaptureDevice.default(for: .audio)
                        }
                        if let micObject = micObject {
                            let audioInput = try AVCaptureDeviceInput(device: micObject)
                            if self.captureSession.canAddInput(audioInput) {
                                self.captureSession.addInput(audioInput)
                                self.audioDevice = micObject
                            }
                        }
                    }

                    var outputInitialized: Bool = false
                    
                    self.useMovieFileOutput = arguments["useMovieFileOutput"] as? Bool ?? false
                    // #warning("forced to use MovieFileOutput for testing purposes")
                    
                    // Add video buffering output
                    
                    if self.useMovieFileOutput {
                        let videoOutput = AVCaptureMovieFileOutput()
                        if self.captureSession.canAddOutput(videoOutput) {
                            self.captureSession.addOutput(videoOutput)
                            for connection in videoOutput.connections {
                                if connection.isVideoMirroringSupported {
                                    connection.isVideoMirrored = true
                                }
                            }
                            outputInitialized = true
                        }
                    } else {
                        let videoOutput = AVCaptureVideoDataOutput()
                        if self.captureSession.canAddOutput(videoOutput) {
                            videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
                            videoOutput.alwaysDiscardsLateVideoFrames = true
                            videoOutput.setSampleBufferDelegate(self, queue: .main)
                            self.captureSession.addOutput(videoOutput)
                            for connection in videoOutput.connections {
                                if connection.isVideoMirroringSupported {
                                    connection.isVideoMirrored = true
                                }
                            }
                            outputInitialized = true
                        }
                        
                        // Add audio buffering output
                        if shouldRecordAudio {
                            let audioOutput = AVCaptureAudioDataOutput()
                            if self.captureSession.canAddOutput(audioOutput) {
                                audioOutput.setSampleBufferDelegate(self, queue: .main)
                                self.captureSession.addOutput(audioOutput)
                            }
                        }
                    }
                    
                    guard outputInitialized else {
                        result(FlutterError(code: "CAMERA_INITIALIZATION_ERROR", message: "Could not initialize output for camera", details: nil).toFlutterResult)
                        return
                    }
                    
                    self.captureSession.commitConfiguration()
                    self.captureSession.startRunning()
                    
                    let dimensions = CMVideoFormatDescriptionGetDimensions(newCameraObject.activeFormat.formatDescription)
                    self.videoOutputHeight = dimensions.height
                    self.videoOutputWidth = dimensions.width
                    let size = ["width": Double(dimensions.width), "height": Double(dimensions.height)]
                    
                    if self.useMovieFileOutput {
                        if let previewLayer = self.previewLayer, let _ = previewLayer.superlayer {
                            previewLayer.removeFromSuperlayer()
                        }
                        self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
                        self.previewLayer!.videoGravity = .resizeAspectFill
                        if let factory = self.factory {
                            factory.frame = CGRect(x: 0, y: 0, width: Int(dimensions.width), height: Int(dimensions.height))
                            factory.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
                        }
                    }
                    
                    var devices: [Dictionary<String, Any>] = []
                    if let videoDevice = self.videoDevice {
                        devices.append([
                            "deviceType": 0,
                            "localizedName" : videoDevice.localizedName,
                            "manufacturer": videoDevice.manufacturer,
                            "deviceId": videoDevice.uniqueID
                        ])
                    }
                    
                    if let audioDevice = self.audioDevice {
                        devices.append([
                            "deviceType": 1,
                            "localizedName" : audioDevice.localizedName,
                            "manufacturer": audioDevice.manufacturer,
                            "deviceId": audioDevice.uniqueID
                        ])
                    }
                    
                    let answer: [String : Any?] = ["textureId": self.textureId, "size": size, "devices": devices]
                    result(answer)
                    
                } catch(let error) {
                    result(FlutterError(code: "CAMERA_INITIALIZATION_ERROR", message: error.localizedDescription, details: nil).toFlutterResult)
                    return
                }
            } else {
                result(FlutterError(code: "CAMERA_INITIALIZATION_ERROR", message: "Permission not granted", details: nil).toFlutterResult)
            }
        }
    }
    
    func takePicture(_ result: @escaping FlutterResult, _ format: NSBitmapImageRep.FileType) {
        guard let imageBuffer = latestBuffer, let nsImage = imageFromSampleBuffer(imageBuffer: imageBuffer),
                let imageData = nsImage.representation(
                using: format,
                properties: [
                    NSBitmapImageRep.PropertyKey.currentFrame: NSBitmapImageRep.PropertyKey.currentFrame.self
                ]
            ), !imageData.isEmpty else {
            result(["error": FlutterError(code: "PHOTO_OUTPUT_ERROR", message: "imageData is empty or invalid", details: nil).toMap])
            return
        }
        result(["imageData": imageData, "error": nil])
    }
    
    func imageFromSampleBuffer(imageBuffer: CVPixelBuffer) -> NSBitmapImageRep? {
        
        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        guard let baseAddress: UnsafeMutableRawPointer = CVPixelBufferGetBaseAddress(imageBuffer) else {
            return nil
        }
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB();
        
        // Create a bitmap graphics context with the sample buffer data
        guard let context = CGContext(
            data: baseAddress,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
        ),
        let quartzImage = context.makeImage() else {
            return nil
        }
        
        CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        // Create an image object from the Quartz image
        let image = NSBitmapImageRep(cgImage:quartzImage);
        if resSize == nil || resSize!.width > CGFloat(width){
            return image
        }
            
        let newImage = NSImage(size: resSize!)
        newImage.lockFocus()
        image.draw(in: NSMakeRect(0, 0, resSize!.width, resSize!.height), from: NSMakeRect(0, 0, image.size.width, image.size.height), operation: NSCompositingOperation.sourceOver, fraction: CGFloat(1), respectFlipped: false, hints: nil)
            
        newImage.unlockFocus()
        newImage.size = resSize!
        return NSBitmapImageRep(data: newImage.tiffRepresentation!)
    }
    
    func startRecording(_ arguments: Dictionary<String, Any>, _ result: @escaping FlutterResult) {
        // Set up the AVAssetWriter (to write to file)
        do {
            if(!isRecording) {
                
                let shouldRecordAudio = arguments["enableAudio"] as? Bool ?? true
                
                self.enableAudio = shouldRecordAudio
                
                // Remove old file
                var fileUrl: URL!
                
                if let selectedURL = arguments["url"] as? String, !selectedURL.isEmpty {
                    fileUrl = URL(fileURLWithPath: selectedURL)
                } else {
                    fileUrl = self.generateVideoFileURL(randomGUID: false)
                }
                
                try? FileManager.default.removeItem(at: fileUrl)
                
                let folderURL = fileUrl.deletingLastPathComponent()
                
                var isDirectory: ObjCBool = false
                if !FileManager.default.fileExists(atPath: folderURL.path, isDirectory: &isDirectory), isDirectory.boolValue {
                    try? FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
                }

                self.videoOutputFileURL = fileUrl
                
                if self.useMovieFileOutput {
                    guard let movieOutput: AVCaptureMovieFileOutput = self.captureSession.outputs.first(where: { $0 is AVCaptureMovieFileOutput }) as? AVCaptureMovieFileOutput else {
                        result(FlutterError(code: "START_RECORDING_ERROR", message: "Could not start AVMovieFileOutput Recording", details: nil).toFlutterResult)
                        return
                    }
                    self.isRecording = true
                    self.savedResult = result
                    movieOutput.startRecording(to: fileUrl, recordingDelegate: self)
                } else {
                    self.videoWriter = try AVAssetWriter(outputURL: fileUrl, fileType: videoFormat)
                    print("Setting up AVAssetWriter")

                    guard let videoWriter = self.videoWriter else {
                        result(FlutterError(code: "CAMERA_INITIALIZATION_ERROR", message: "Could not initialize Video Writer", details: nil).toFlutterResult)
                        return
                    }
                    
                    videoWriter.shouldOptimizeForNetworkUse = true
                    
                    videoOutputQueue = DispatchQueue(label: "videoQueue", qos: .utility, attributes: .concurrent, autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.inherit, target: DispatchQueue.global())
                    guard let videoOutputQueue = videoOutputQueue else {
                        result(FlutterError(code: "START_RECORDING_ERROR", message: "videoOutputQueue not initialized", details: nil).toFlutterResult)
                        isRecording = false
                        return
                    }
                    
                    videoOutputQueue.async {
                        // Add Video Writer Video Input
                        var videoWriterVideoInputSettings: [String : Any] = [
                            AVVideoWidthKey  : self.videoOutputWidth!,
                            AVVideoHeightKey : self.videoOutputHeight!,
                        ]
                        
                        if #available(macOS 10.13, *) {
                            videoWriterVideoInputSettings[AVVideoCodecKey] = AVVideoCodecType.h264
                        } else {
                            videoWriterVideoInputSettings[AVVideoCodecKey] = AVVideoCodecH264
                        }
                        
                        if let settingsAssistant = self.settingsAssistant, let videoSettings = settingsAssistant.videoSettings, videoWriter.canApply(outputSettings: videoSettings, forMediaType: .video) {
                            videoWriterVideoInputSettings = videoSettings
                        }

                        
                        let videoWriterVideoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoWriterVideoInputSettings)
                        videoWriterVideoInput.expectsMediaDataInRealTime = true
                        if (videoWriter.canAdd(videoWriterVideoInput))
                        {
                            videoWriter.add(videoWriterVideoInput)
                        }

                        // Add Video Writer Audio Input
                        if self.enableAudio {
                            var videoWriterAudioInputSettings : [String : Any] = [
                                AVFormatIDKey : kAudioFormatMPEG4AAC,
                                AVSampleRateKey : 44100,
                                AVEncoderBitRateKey : 64000,
                                AVNumberOfChannelsKey: 1
                            ]
                            
                            if let settingsAssistant = self.settingsAssistant, let audioSettings = settingsAssistant.audioSettings, videoWriter.canApply(outputSettings: audioSettings, forMediaType: .audio) {
                                videoWriterAudioInputSettings = audioSettings
                            }
                            
                            let videoWriterAudioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: videoWriterAudioInputSettings)
                            videoWriterAudioInput.expectsMediaDataInRealTime = true
                            if (videoWriter.canAdd(videoWriterAudioInput))
                            {
                                videoWriter.add(videoWriterAudioInput)
                            }
                        }
                        
                        // video buffering output
                        if let videoOutput = self.captureSession.outputs.first(where: { $0 is AVCaptureVideoDataOutput }) as? AVCaptureVideoDataOutput {
                            videoOutput.setSampleBufferDelegate(self, queue: videoOutputQueue)
                        }
                        
                        // audio buffering output
                        if shouldRecordAudio {
                            if let audioOutput = self.captureSession.outputs.first(where: { $0 is AVCaptureAudioDataOutput }) as? AVCaptureAudioDataOutput {
                                audioOutput.setSampleBufferDelegate(self, queue: videoOutputQueue)
                            }
                        }
                        
                        print("Finished Setting up AVAssetWriter")
                        
                        
                        print("Starting AVAssetWriter Writing")
                        if videoWriter.startWriting() {
                            print("Started AVAssetWriter Writing")
                            videoWriter.startSession(atSourceTime: CMTime(seconds: CACurrentMediaTime(), preferredTimescale: CMTimeScale(NSEC_PER_SEC)) /*CMTimeMakeWithSeconds(CACurrentMediaTime(), preferredTimescale: 240)*/)
                            self.isRecording = true
                            DispatchQueue.main.async {
                                if let maxVideoDuration = arguments["maxVideoDuration"] as? Double, maxVideoDuration > 0 {
                                    if #available(macOS 10.12, *) {
                                        Timer.scheduledTimer(withTimeInterval: maxVideoDuration, repeats: false) { timer in
                                            if self.isRecording && videoWriter.status == .writing {
                                                self.stopRecording { callbackResult in
                                                    if let outputChannel = self.outputChannel {
                                                        outputChannel.invokeMethod("onVideoRecordingFinished", arguments: callbackResult)
                                                    }
                                                }
                                            }
                                            timer.invalidate()
                                        }
                                    } else {
                                        Timer.scheduledTimer(timeInterval: maxVideoDuration, target: self, selector: #selector(self.stopRecordingSelector), userInfo: nil, repeats: false)
                                    }
                                }
                                result(["started": true, "error": nil])
                            }
                        } else {
                            result(FlutterError(code: "START_RECORDING_ERROR", message: "Could not start AVAssetWriter session", details: nil).toFlutterResult)
                        }
                    }
                }
                
                
            } else {
                result(FlutterError(code: "CONCURRENCY_ERROR", message: "Already recording video", details: nil).toFlutterResult)
            }
        } catch(let error) {
            result(FlutterError(code: "START_RECORDING_ERROR", message: error.localizedDescription, details: nil).toFlutterResult)
            return
        }
        
        
    }
    
    func stopRecording(_ result: @escaping FlutterResult) {
        guard let captureSession = self.captureSession, captureSession.isRunning else {
            result(FlutterError(code: "CAMERA_INITIALIZATION_ERROR", message: "CaptureSession not found or not running", details: nil).toFlutterResult)
            return
        }
        if(!self.isRecording) {
            result(FlutterError(code: "CAMERA_NOT_RECORDING_ERROR", message: "Camera not recording", details: nil).toFlutterResult)
            return
        }
        if self.useMovieFileOutput {
            guard let movieOutput: AVCaptureMovieFileOutput = self.captureSession.outputs.first(where: { $0 is AVCaptureMovieFileOutput }) as? AVCaptureMovieFileOutput else {
                result(FlutterError(code: "STOP_RECORDING_ERROR", message: "Could not stop AVMovieFileOutput Recording - Output not found", details: nil).toFlutterResult)
                return
            }
            self.isRecording = false
            self.savedResult = result
            movieOutput.stopRecording()
        } else {
            guard let videoWriter = videoWriter, let videoOutputFileURL = self.videoOutputFileURL, let videoWriterVideoInput = videoWriter.inputs.first(where: { $0.mediaType == .video }), let videoOutputQueue: DispatchQueue = self.videoOutputQueue else {
                result(FlutterError(code: "CAMERA_INITIALIZATION_ERROR", message: "AVAssetWriter not found", details: nil).toFlutterResult)
                return
            }
            self.isRecording = false
            videoOutputQueue.async {
                if videoWriter.status == .writing {
                    videoWriterVideoInput.markAsFinished()
                    if self.enableAudio, let videoWriterAudioInput = videoWriter.inputs.first(where: { $0.mediaType == .audio }) {
                        videoWriterAudioInput.markAsFinished()
                    }
                }
                if let latestFrameWrittenTimeStamp = self.latestVideoFrameWrittenTimeStamp {
                    videoWriter.endSession(atSourceTime: latestFrameWrittenTimeStamp)
                }
                videoWriter.finishWriting {
                    let videoWriterStatus: AVAssetWriter.Status = videoWriter.status
                    print("Finished AVAssetWriter Writing with status: \(videoWriterStatus)")
                    DispatchQueue.main.async {
                        switch(videoWriterStatus) {
                        case .completed:
                            guard let videoData = try? Data(contentsOf: videoOutputFileURL), !videoData.isEmpty else {
                                result(["error": FlutterError(code: "ASSET_WRITER_FAIL", message: "File is empty at url: \(videoOutputFileURL.absoluteURL)", details: nil).toFlutterResult])
                                return
                            }
                            print("Video Recorded And Saved At: \(videoOutputFileURL.absoluteURL)")
                            result(["videoData": videoData, "url": videoOutputFileURL.absoluteURL.path, "error": nil])
                        default:
                            result(FlutterError(code: "ASSET_WRITER_FAIL", message: "File not saved at \(videoOutputFileURL.absoluteURL.path) - \(videoWriter.error?.localizedDescription ?? "")", details: nil).toFlutterResult)
                        }
                        self.videoWriter = nil
                    }
                }
            }
        }
        
    }
    
    @objc
    func stopRecordingSelector(){
        guard let outputChannel = self.outputChannel else {
            fatalError("OutputChannel not found")
        }
        if self.isRecording {
            self.stopRecording { callbackResult in
                outputChannel.invokeMethod("onVideoRecordingFinished", arguments: callbackResult)
            }
        }
    }
    
    func destroy(_ result: @escaping FlutterResult) {
        if (self.videoDevice == nil) {
            result(FlutterError(code: "CAMERA_DESTROY_ERROR",
                                message: "Called destroy() while already destroyed!",
                                details: nil).toFlutterResult)
            return
        }
        
        self.isDestroyed = true
        
        if self.isRecording, let videoWriter = videoWriter, videoWriter.status == .writing {
            videoWriter.cancelWriting()
            self.isRecording = false
            self.videoWriter = nil
        }
        
        self.captureSession.stopRunning()
        for input in self.captureSession.inputs {
            self.captureSession.removeInput(input)
        }
        for output in self.captureSession.outputs {
            self.captureSession.removeOutput(output)
        }
        
        if let textureId = self.textureId {
            self.registry.unregisterTexture(textureId)
        }
        
        self.latestBuffer = nil
        self.captureSession = nil
        self.videoDevice = nil
        self.textureId = nil
        
        result(true)
        
    }
    
    private var latestVideoFrameWrittenTimeStamp: CMTime!
    private var latestAudioFrameWrittenTimeStamp: CMTime!
    
    var canWrite: Bool {
        videoWriter != nil && videoWriter!.status == .writing
    }
    
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard !isDestroyed, textureId != nil else {
            return
        }
        
        let isBufferAudio: Bool = output is AVCaptureAudioDataOutput
        
        i += 1
        
        if !isBufferAudio {
            latestBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
            registry.textureFrameAvailable(textureId)
        }
        
        if !self.useMovieFileOutput, isRecording, let captureSession = self.captureSession, captureSession.isRunning, let videoWriter = self.videoWriter, let videoOutputQueue = videoOutputQueue,
           CMSampleBufferDataIsReady(sampleBuffer) {
            videoOutputQueue.async {
                let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                
                if self.enableAudio, isBufferAudio, let audio = videoWriter.inputs.first(where: { $0.mediaType == .audio }), !connection.audioChannels.isEmpty, let connectionOutput = connection.output, let _ = connectionOutput.connection(with: .audio), audio.isReadyForMoreMediaData {
                    if let latestAudioFrameWrittenTimeStamp = self.latestAudioFrameWrittenTimeStamp, latestAudioFrameWrittenTimeStamp > time {
                        print("Wrong frame order: Previous: \(latestAudioFrameWrittenTimeStamp) - Current: \(time)")
                        return
                    }
                    if self.canWrite {
                        let result: Bool = audio.append(sampleBuffer)
                        if(!result && videoWriter.status == .failed) {
                            print("Failed to write audio input: AVAssetWriter Error - " + videoWriter.error.debugDescription + " - Frame Order: " + "Previous: \(self.latestAudioFrameWrittenTimeStamp) - Current: \(time)")
                        } else if result {
                            self.latestAudioFrameWrittenTimeStamp = time
                        }
                    }
                    
                }
                if !isBufferAudio, let camera = videoWriter.inputs.first(where: { $0.mediaType == .video }), let connectionOutput = connection.output, let _ = connectionOutput.connection(with: .video), camera.isReadyForMoreMediaData {
                    if let latestVideoFrameWrittenTimeStamp = self.latestVideoFrameWrittenTimeStamp, latestVideoFrameWrittenTimeStamp > time {
                        print("Wrong frame order: Previous: \(latestVideoFrameWrittenTimeStamp) - Current: \(time)")
                        return
                    }
                    if self.canWrite {
                        let result: Bool = camera.append(sampleBuffer)
                        if !result && videoWriter.status == .failed {
                            print("Failed to write video input: AVAssetWriter Error - " + videoWriter.error.debugDescription + " - Frame Order: " + "Previous: \(self.latestVideoFrameWrittenTimeStamp) - Current: \(time)")
                        } else if result {
                            self.latestVideoFrameWrittenTimeStamp = time
                        }
                    }
                }
            }
        }
        
        // Limit the analyzer because the texture output will freeze otherwise
        if i / 10 == 1 {
            i = 0
        } else {
            return
        }
    }
    
    // MOVIE FILE OUTPUT MODE
    public func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        guard let savedResult = savedResult else {
            print("FlutterResult callback not registered")
            return
        }
        if let error = error {
            savedResult(FlutterError(code: "MOVIE_FILE_OUTPUT_FAIL", message: "File not saved at \(videoOutputFileURL.absoluteURL.path) - \(error.localizedDescription)", details: nil).toFlutterResult)
            return
        }
        guard let videoData = try? Data(contentsOf: outputFileURL), !videoData.isEmpty else {
            savedResult(["error": FlutterError(code: "MOVIE_FILE_OUTPUT_FAIL", message: "File is empty at url: \(outputFileURL.absoluteURL)", details: nil).toFlutterResult])
            return
        }
        print("Video Recorded And Saved At: \(outputFileURL.absoluteURL)")
        savedResult(["videoData": videoData, "url": outputFileURL.absoluteURL.path, "error": nil])
    }
    
}
