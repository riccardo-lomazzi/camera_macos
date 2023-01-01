import Cocoa
import FlutterMacOS
import AVFoundation

public class CameraMacosPlugin: NSObject, FlutterPlugin, FlutterTexture, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate, AVAssetWriterDelegate {
    
    let registry: FlutterTextureRegistry
    let outputChannel: FlutterMethodChannel!
    
    // Texture id of the camera preview
    var textureId: Int64!
    
    // Capture session of the camera
    var captureSession: AVCaptureSession!
    
    // The selected camera
    var videoDevice: AVCaptureDevice!
    
    // Image to be sent to the texture
    var latestBuffer: CVImageBuffer!
    
    // The asset writer to write a file on disk
    var videoWriter: AVAssetWriter!
    
    // Temp variabile to store FlutterResult methods
    var videoOutputFileURL: URL!
    
    
    // Semaphore variable
    var isTakingPicture: Bool = false
    var isRecording: Bool = false
    var i: Int = 0
    var videoOutputQueue: DispatchQueue!
    var isDestroyed = false
    
    init(_ registry: FlutterTextureRegistry, _ outputChannel: FlutterMethodChannel) {
        self.registry = registry
        self.outputChannel = outputChannel
        super.init()
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let inputChannel = FlutterMethodChannel(name: "camera_macos", binaryMessenger: registrar.messenger)
        let outputChannel = FlutterMethodChannel(name: "camera_macos", binaryMessenger: registrar.messenger)
        let instance = CameraMacosPlugin(registrar.textures, outputChannel)
        registrar.addMethodCallDelegate(instance, channel: inputChannel)
    }
    
    public func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
        if latestBuffer == nil {
            return nil
        }
        return Unmanaged<CVPixelBuffer>.passRetained(latestBuffer)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "listDevices":
            let arguments = call.arguments as? Dictionary<String, Any> ?? [:]
            listDevices(arguments, result)
        case "initialize":
            guard let arguments = call.arguments as? Dictionary<String, Any> else {
                result(FlutterError(code: "INVALID_ARGS", message: "", details: nil).toMap)
                return
            }
            initCamera(arguments, result)
        case "takePicture":
            takePicture(result)
        case "startRecording":
            let arguments = call.arguments as? Dictionary<String, Any> ?? [:]
            startRecording(arguments, result)
        case "stopRecording":
            stopRecording(result)
        case "destroy":
            destroy(result)
        default:
            result(FlutterMethodNotImplemented)
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
        var fileUrl = paths[0].appendingPathComponent("output.mp4")
        if randomGUID {
            fileUrl = paths[0].appendingPathComponent(UUID().uuidString + ".mp4")
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
                        "deviceName" : device.localizedName,
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
                    // for now, audio can be obtained only from the same source
                    newCameraObject = capturedVideoDevices.first(where: { $0.uniqueID == deviceId })
                } else {
                    newCameraObject = capturedVideoDevices.first
                }
                
                guard let newCameraObject: AVCaptureDevice = newCameraObject else {
                    result(FlutterError(code: "CAMERA_INITIALIZATION_ERROR", message: "Could not find a suitable camera on this device", details: nil).toFlutterResult)
                    return
                }
                self.videoDevice = newCameraObject
                do {
                    let focusPoint: CGPoint = .init(x: 0.5, y: 0.5)
                    try newCameraObject.lockForConfiguration()
                    if newCameraObject.isFocusPointOfInterestSupported {
                        newCameraObject.focusPointOfInterest = focusPoint
                    }
                    if newCameraObject.isFocusModeSupported(.autoFocus) {
                        newCameraObject.focusMode = .autoFocus
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

                    if shouldRecordAudio, let defaultMicrophone = AVCaptureDevice.default(for: .audio) {
                        let audioInput = try AVCaptureDeviceInput(device: defaultMicrophone)
                        if self.captureSession.canAddInput(audioInput) {
                            self.captureSession.addInput(audioInput)
                        }
                    }
                    
                    var outputInitialized: Bool = false
                    
                    // Add video buffering output
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
                        
                    }
                    
                    // Add audio buffering output
                    let audioOutput = AVCaptureAudioDataOutput()
                    if self.captureSession.canAddOutput(audioOutput) {
                        audioOutput.setSampleBufferDelegate(self, queue: .main)
                        self.captureSession.addOutput(audioOutput)
                        outputInitialized = true
                    }
                    
                    guard outputInitialized else {
                        result(FlutterError(code: "CAMERA_INITIALIZATION_ERROR", message: "Could not initialize output for camera", details: nil).toFlutterResult)
                        return
                    }
                    
                    self.captureSession.commitConfiguration()
                    self.captureSession.startRunning()
                    let dimensions = CMVideoFormatDescriptionGetDimensions(newCameraObject.activeFormat.formatDescription)
                    let size = ["width": Double(dimensions.width), "height": Double(dimensions.height)]
                    let answer: [String : Any?] = ["textureId": self.textureId, "size": size]
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
    
    func takePicture(_ result: @escaping FlutterResult) {
        guard let imageBuffer = latestBuffer, let nsImage = imageFromSampleBuffer(imageBuffer: imageBuffer), let imageData = nsImage.tiffRepresentation, !imageData.isEmpty else {
            result(["error": FlutterError(code: "PHOTO_OUTPUT_ERROR", message: "imageData is empty or invalid", details: nil).toMap])
            return
        }
        result(["imageData": imageData, "error": nil])
    }
    
    func startRecording(_ arguments: Dictionary<String, Any>, _ result: @escaping FlutterResult) {
        // Set up the AVAssetWriter (to write to file)
        do {
            if(!isRecording) {
                
                var fileUrl: URL!
                
                if let selectedURL = arguments["url"] as? String, !selectedURL.isEmpty {
                    fileUrl = URL(fileURLWithPath: selectedURL)
                } else {
                    fileUrl = self.generateVideoFileURL(randomGUID: false)
                    
                }
                
                // Remove old file
                try? FileManager.default.removeItem(at: fileUrl)
                self.videoOutputFileURL = fileUrl
                
                self.videoWriter = try AVAssetWriter(outputURL: fileUrl, fileType: .mp4)
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
                        AVVideoWidthKey  : 1280,
                        AVVideoHeightKey : 720,
                    ]
                    if #available(macOS 10.13, *) {
                        videoWriterVideoInputSettings[AVVideoCodecKey] = AVVideoCodecType.h264
                    } else {
                        videoWriterVideoInputSettings[AVVideoCodecKey] = AVVideoCodecH264
                    }
                    
                    let videoWriterVideoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoWriterVideoInputSettings)
                    videoWriterVideoInput.expectsMediaDataInRealTime = true
                    if (videoWriter.canAdd(videoWriterVideoInput))
                    {
                        videoWriter.add(videoWriterVideoInput)
                    }

                    // Add Video Writer Audio Input
                    let videoWriterAudioInputSettings : [String : Any] = [
                        AVFormatIDKey : kAudioFormatMPEG4AAC,
                        AVSampleRateKey : 44100,
                        AVEncoderBitRateKey : 64000,
                        AVNumberOfChannelsKey: 1
                    ]
                    
                    let videoWriterAudioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: videoWriterAudioInputSettings)
                    videoWriterAudioInput.expectsMediaDataInRealTime = true
                    if (videoWriter.canAdd(videoWriterAudioInput))
                    {
                        videoWriter.add(videoWriterAudioInput)
                    }
                    
                    print("Finished Setting up AVAssetWriter")
                    
                    self.isRecording = true
                    print("Starting AVAssetWriter Writing")
                    if videoWriter.startWriting() {
                        print("Started AVAssetWriter Writing")
                        videoWriter.startSession(atSourceTime: CMTimeMakeWithSeconds(CACurrentMediaTime(), preferredTimescale: 240))
                        DispatchQueue.main.async {
                            if let maxVideoDuration = arguments["maxVideoDuration"] as? Double, maxVideoDuration > 0 {
                                if #available(macOS 10.12, *) {
                                    Timer.scheduledTimer(withTimeInterval: maxVideoDuration, repeats: false) { timer in
                                        if self.isRecording {
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
                            result(true)
                        }
                    } else {
                        result(FlutterError(code: "START_RECORDING_ERROR", message: "Could not start AVAssetWriter session", details: nil).toFlutterResult)
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
        guard let captureSession = self.captureSession, captureSession.isRunning, let videoWriter = videoWriter, let videoOutputFileURL = self.videoOutputFileURL, let videoWriterVideoInput = videoWriter.inputs.first(where: { $0.mediaType == .video }), let videoWriterAudioInput = videoWriter.inputs.first(where: { $0.mediaType == .audio }), let videoOutputQueue = self.videoOutputQueue else {
            result(FlutterError(code: "CAMERA_INITIALIZATION_ERROR", message: "AVAssetWriter not found", details: nil).toFlutterResult)
            return
        }
        if(!self.isRecording) {
            result(FlutterError(code: "CAMERA_NOT_RECORDING_ERROR", message: "Camera not recording", details: nil).toFlutterResult)
        } else {
            self.isRecording = false
            videoOutputQueue.async {
                if videoWriter.status == .writing {
                    videoWriterVideoInput.markAsFinished()
                    videoWriterAudioInput.markAsFinished()
                }
                videoWriter.finishWriting {
                    print("Finished AVAssetWriter Writing")
                    DispatchQueue.main.async {
                        switch(videoWriter.status) {
                        case .completed:
                            guard let videoData = try? Data(contentsOf: videoOutputFileURL), !videoData.isEmpty  else {
                                result(["error": FlutterError(code: "ASSET_WRITER_FAIL", message: "File is empty at url: \(videoOutputFileURL.absoluteURL)", details: nil).toMap])
                                return
                            }
                            print("Video Recorded And Saved At: \(videoOutputFileURL.absoluteURL)")
                            result(["videoData": videoData, "error": nil])
                            self.videoWriter = nil
                        default:
                            result(FlutterError(code: "ASSET_WRITER_FAIL", message: "File not saved - \(videoWriter.error?.localizedDescription ?? "")", details: nil).toFlutterResult)
                        }
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
        
        self.registry.unregisterTexture(self.textureId)
        
        self.latestBuffer = nil
        self.captureSession = nil
        self.videoDevice = nil
        self.textureId = nil
        
        result(true)
        
    }
    
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard !isDestroyed else {
            return
        }
        
        let isBufferAudio: Bool = output is AVCaptureAudioDataOutput
        
        i += 1
        
        if !isBufferAudio {
            latestBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
            registry.textureFrameAvailable(textureId)
        }
        
        if isRecording, let captureSession = self.captureSession, captureSession.isRunning, let videoWriter = self.videoWriter, let videoOutputQueue = videoOutputQueue,
           CMSampleBufferDataIsReady(sampleBuffer) {
            videoOutputQueue.async {
                if isBufferAudio, let audio = videoWriter.inputs.first(where: { $0.mediaType == .audio }), !connection.audioChannels.isEmpty, let connectionOuput = connection.output, let _ = connectionOuput.connection(with: .audio), audio.isReadyForMoreMediaData {
                    audio.append(sampleBuffer)
                }
                if !isBufferAudio, let camera = videoWriter.inputs.first(where: { $0.mediaType == .video }), let connectionOuput = connection.output, let _ = connectionOuput.connection(with: .video), camera.isReadyForMoreMediaData {
                    camera.append(sampleBuffer)
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
    
    func imageFromSampleBuffer(imageBuffer: CVPixelBuffer) -> NSImage? {
        
        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        guard let baseAddress: UnsafeMutableRawPointer = CVPixelBufferGetBaseAddress(imageBuffer) else {
            return nil
        }
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB();
        
        // Create a bitmap graphics context with the sample buffer data
        guard let context = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue), let quartzImage = context.makeImage() else {
            return nil
        }
        
        CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        // Create an image object from the Quartz image
        let image = NSImage(cgImage:quartzImage, size: NSSize(width: width, height: height));
        
        return (image);
    }
    
}
