import Cocoa
import FlutterMacOS
import AVFoundation

public class CameraMacosPlugin: NSObject, FlutterPlugin, FlutterTexture, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    
    let registry: FlutterTextureRegistry
    
    // Texture id of the camera preview
    var textureId: Int64!
    
    // Capture session of the camera
    var captureSession: AVCaptureSession!
    
    // The selected camera
    var videoDevice: AVCaptureDevice!
    var audioDevice: AVCaptureDevice!
    
    // Image to be sent to the texture
    var latestBuffer: CVImageBuffer!
    
    // The asset writer to write a file on disk
    var videoWriter: AVAssetWriter!
    var videoWriterInputPixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor!
    
    // Output channel for calling Flutter-code methods
    var outputChannel: FlutterMethodChannel!
    
    // Semaphore variable
    var isTakingPicture: Bool = false
    var isRecording: Bool = false
    var i: Int = 0
    var videoOutputQueue: DispatchQueue!
    
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
        case "initialize":
            guard let arguments = call.arguments as? Dictionary<String, Any> else {
                result(FlutterError(code: "INVALID_ARGS", message: "", details: nil))
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
    
    var videoFileURL: URL {
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        let fileUrl = paths[0].appendingPathComponent("output.mp4")
        return fileUrl
    }
    
    func initCamera(_ arguments: Dictionary<String, Any>, _ result: @escaping FlutterResult) {
        self.requestPermission { granted in
            if granted {
                self.textureId = self.registry.register(self)
                self.captureSession = AVCaptureSession()
                self.captureSession.beginConfiguration()
                if let sessionPresetArg = arguments["type"] as? Int {
                    switch(sessionPresetArg) {
                    case 0:
                        self.captureSession.sessionPreset = .photo
                    case 1:
                        self.captureSession.sessionPreset = .hd1280x720
                    default:
                        self.captureSession.sessionPreset = .photo
                    }
                }
                var newCameraObject: AVCaptureDevice!
                var newMicrophoneObject: AVCaptureDevice!
                
                if #available(macOS 10.15, *) {
                    newCameraObject = AVCaptureDevice.captureDevice(deviceTypes: [.builtInWideAngleCamera], mediaType: .video)
                    newMicrophoneObject = AVCaptureDevice.captureDevice(deviceTypes: [.builtInMicrophone], mediaType: .audio)
                } else {
                    newCameraObject = AVCaptureDevice.captureDevice(mediaType: .video)
                    newMicrophoneObject = AVCaptureDevice.captureDevice(mediaType: .audio)
                }
                
                guard let newCameraObject: AVCaptureDevice = newCameraObject, let newMicrophoneObject: AVCaptureDevice = newMicrophoneObject else {
                    result(FlutterError(code: "CAMERA_INITIALIZATION_ERROR", message: "Could not find a suitable camera on this device", details: nil))
                    return
                }
                self.videoDevice = newCameraObject
                self.audioDevice = newMicrophoneObject
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
                    let audioInput = try AVCaptureDeviceInput(device: newMicrophoneObject)
                    
                    if self.captureSession.canAddInput(videoInput) {
                        self.captureSession.addInput(videoInput)
                    }
                    
//                    if self.captureSession.canAddInput(audioInput) {
//                        self.captureSession.addInput(audioInput)
//                    }
                    
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
                    
                    // Set up the AVAssetWriter (to write to file)
                    self.videoWriter = try AVAssetWriter(outputURL: self.videoFileURL, fileType: AVFileType.mp4)
                    print("Setup AVAssetWriter")

                    guard let videoWriter = self.videoWriter else {
                        result(FlutterError(code: "CAMERA_INITIALIZATION_ERROR", message: "Could not initialize Video Writer", details: nil))
                        return
                    }

                    // Add Video Writer Video Input
                    var videoWriterVideoInputSettings: [String : Any] = [
                        AVVideoWidthKey  : 720,
                        AVVideoHeightKey : 1280,
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
                    
                    // PixelWriter
                    self.videoWriterInputPixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
                        assetWriterInput: videoWriterVideoInput,
                        sourcePixelBufferAttributes: [
                            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                            kCVPixelBufferWidthKey as String: 1280,
                            kCVPixelBufferHeightKey as String: 768
                        ]
                    )
                    
                    guard outputInitialized else {
                        result(FlutterError(code: "CAMERA_INITIALIZATION_ERROR", message: "Could not initialize output for camera", details: nil))
                        return
                    }
                    
                    self.captureSession.commitConfiguration()
                    self.captureSession.startRunning()
                    let dimensions = CMVideoFormatDescriptionGetDimensions(newCameraObject.activeFormat.formatDescription)
                    let size = ["width": Double(dimensions.width), "height": Double(dimensions.height)]
                    let answer: [String : Any?] = ["textureId": self.textureId, "size": size]
                    result(answer)
                    
                } catch(let error) {
                    result(FlutterError(code: "CAMERA_INITIALIZATION_ERROR", message: error.localizedDescription, details: nil))
                    return
                }
            } else {
                result(FlutterError(code: "CAMERA_INITIALIZATION_ERROR", message: "Permission not granted", details: nil))
            }
        }
    }
    
    func takePicture(_ result: @escaping FlutterResult) {
        guard let imageBuffer = latestBuffer, let nsImage = imageFromSampleBuffer(imageBuffer: imageBuffer), let imageData = nsImage.tiffRepresentation, !imageData.isEmpty else {
            result(["error": FlutterError(code: "PHOTO_OUTPUT_ERROR", message: "imageData is empty or invalid", details: nil)])
            return
        }
        result(["imageData": imageData, "error": nil])
    }
    
    func startRecording(_ arguments: Dictionary<String, Any>, _ result: @escaping FlutterResult) {
        guard let videoWriter = videoWriter else {
            result(FlutterError(code: "CAMERA_INITIALIZATION_ERROR", message: "AVAssetWriter not found", details: nil))
            return
        }
        guard let cameraSession = captureSession, let masterClock = cameraSession.masterClock else {
            result(FlutterError(code: "CAMERA_INITIALIZATION_ERROR", message: "MasterClock not found", details: nil))
            return
        }
        if(!isRecording) {
            isRecording = true
            // Remove old file
            let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
            let fileUrl = paths[0].appendingPathComponent("output.mp4")
            try? FileManager.default.removeItem(at: fileUrl)
            videoOutputQueue = DispatchQueue(label: "videoQueue", qos: .utility, attributes: .concurrent, autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.inherit, target: DispatchQueue.global())
            guard let videoOutputQueue = videoOutputQueue else {
                result(FlutterError(code: "START_RECORDING_ERROR", message: "videoOutputQueue not initialized", details: nil))
                isRecording = false
                return
            }
            if let maxVideoDuration = arguments["maxVideoDuration"] as? Double, maxVideoDuration > 0 {
                if #available(macOS 10.12, *) {
                    Timer.scheduledTimer(withTimeInterval: maxVideoDuration, repeats: false) { timer in
                        self.stopRecording(result)
                    }
                }
                #warning("Need to implement code for macOS 10.11 or older versions")
            }
            videoOutputQueue.async {
                videoWriter.startWriting()
                videoWriter.startSession(atSourceTime: CMClockGetTime(masterClock))
            }
            result(true)
        } else {
            result(FlutterError(code: "CONCURRENCY_ERROR", message: "Already recording video", details: nil))
        }
    }
    
    func stopRecording(_ result: @escaping FlutterResult) {
        guard let videoWriter = videoWriter, let videoWriterVideoInput = videoWriter.inputs.first(where: { $0.mediaType == .video }), let videoWriterAudioInput = videoWriter.inputs.first(where: { $0.mediaType == .audio }) else {
            result(FlutterError(code: "CAMERA_INITIALIZATION_ERROR", message: "AVAssetWriter not found", details: nil))
            return
        }
        if(!isRecording) {
            result(FlutterError(code: "CAMERA_NOT_RECORDING_ERROR", message: "Camera not recording", details: nil))
        } else {
            if videoWriter.status == .writing {
                videoWriterVideoInput.markAsFinished()
                videoWriterAudioInput.markAsFinished()
            }
            videoWriter.finishWriting {
                self.isRecording = false
                DispatchQueue.main.async {
                    switch(videoWriter.status) {
                    case .completed:
                        guard let videoData = try? Data(contentsOf: self.videoFileURL), !videoData.isEmpty  else {
                            result(["error": FlutterError(code: "ASSET_WRITER_FAIL", message: "File is empty", details: nil)])
                            return
                        }
                        result(["videoData": videoData, "error": nil])
                    default:
                        result(FlutterError(code: "ASSET_WRITER_FAIL", message: "File not saved", details: nil))
                    }
                }
            }
            
        }
    }
    
    func destroy(_ result: @escaping FlutterResult) {
        if (videoDevice == nil) {
            result(FlutterError(code: "CAMERA_DESTROY_ERROR",
                                message: "Called destroy() while already destroyed!",
                                details: nil))
            return
        }
        captureSession.stopRunning()
        for input in captureSession.inputs {
            captureSession.removeInput(input)
        }
        for output in captureSession.outputs {
            captureSession.removeOutput(output)
        }
        registry.unregisterTexture(textureId)
        
        latestBuffer = nil
        captureSession = nil
        videoDevice = nil
        textureId = nil
        
        result(nil)
    }
    
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        latestBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        registry.textureFrameAvailable(textureId)
        
        if isRecording {
            guard let videoWriter = self.videoWriter, let videoOutputQueue = videoOutputQueue,
                  CMSampleBufferDataIsReady(sampleBuffer) else { return }
            
            if let audio = videoWriter.inputs.first(where: { $0.mediaType == .audio }), !connection.audioChannels.isEmpty, audio.isReadyForMoreMediaData
            {
                videoOutputQueue.async {
                    audio.append(sampleBuffer)
                }
            }
            
            if let camera = videoWriter.inputs.first(where: { $0.mediaType == .video }), camera.isReadyForMoreMediaData {
                
                videoOutputQueue.async {
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
