//
//  FrameHandler.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 6/25/24.
//

import Vision
import Photos
import SwiftUI
import CoreImage
import AVFoundation

class FrameHandler: NSObject, ObservableObject {
    private var savedISO: Float?
    private let context = CIContext()
    private var isRecordingVideo = false
    private var permissionGranted = false
    private var visionModel: VNCoreMLModel?
    private var videoDevice: AVCaptureDevice?
    private var savedExposureDuration: CMTime?
    private var movieOutput = AVCaptureMovieFileOutput()
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    
    @Published var frame: CGImage?
    @Published var boundingBox: CGRect?
    @Published var fetchedVideoURL: URL?
    @Published var fetchedGraphURL: URL?
    @Published var recordedVideoURL: URL?
    @Published var isSessionReady = false
    @Published var currentView: String = ""
    @Published var captureSession: AVCaptureSession?
    @Published var irisBoundingBoxes: [CGRect] = []
    @Published var pupilBoundingBoxes: [CGRect] = []
    @Published var uRL = "http://a8a175088b809630c.awsglobalaccelerator.com:8000/cyclops/upload/"
    //    @Published var uRL = "http://192.168.4.108:8000/cyclops/upload/" //local server
    
    override init() {
        super.init()
        loadModel()
        checkPermission()
    }
    
    func loadModel(){
        do{
            let model = try EyeDetector(configuration: MLModelConfiguration()).model
            visionModel = try VNCoreMLModel(for: model)
            print("Model loaded successfully")
        }catch{
            print("Failed to load model: \(error)")
        }
    }
    
    // Check for camera permission
    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionGranted = true
            setupCaptureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [unowned self] granted in
                self.permissionGranted = granted
                if granted {
                    self.setupCaptureSession()
                }
            }
        default:
            permissionGranted = false
        }
    }
    
    //To select the desired camera
    func bestDevice(deviceTypes: [AVCaptureDevice.DeviceType], position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: deviceTypes,
            mediaType: .video,
            position: position
        )
        return discoverySession.devices.first(where: { $0.position == position })
    }
    
    // Setup camera session
    func setupCaptureSession() {
        guard permissionGranted else { return }
        
        sessionQueue.async {
            self.captureSession = AVCaptureSession()
            guard let captureSession = self.captureSession else { return }
            
            captureSession.beginConfiguration()
            captureSession.sessionPreset = .hd1920x1080 // Adjust recording resolution as needed
            do {
                // Determine desired camera based on currentView
                var deviceTypes: [AVCaptureDevice.DeviceType] = [
                    .builtInUltraWideCamera,  // Highest priority for 0.5x zoom
                    .builtInWideAngleCamera,
                    .builtInDualWideCamera,
                    .builtInDualCamera,
                    .builtInTripleCamera,
                    .builtInTelephotoCamera
                ]
                let position: AVCaptureDevice.Position
                deviceTypes = [.builtInUltraWideCamera, .builtInWideAngleCamera, .builtInDualWideCamera, .builtInTelephotoCamera, .builtInDualCamera, .builtInTripleCamera]
                if self.currentView == "VOMS"{
                    position = .front
                }else{
                    position = .back
                }
                
                guard let videoDevice = self.bestDevice(deviceTypes: deviceTypes, position: position) else {
                    print("Desired camera not available")
                    return
                }
                self.videoDevice = videoDevice
                
                let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
                if captureSession.canAddInput(videoDeviceInput) {
                    captureSession.addInput(videoDeviceInput)
                }
                
                // Setup video output
                let videoOutput = AVCaptureVideoDataOutput()
                videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sampleBufferQueue", qos: .userInitiated))
                if captureSession.canAddOutput(videoOutput) {
                    captureSession.addOutput(videoOutput)
                }
                
                // Add movie output for recording
                if captureSession.canAddOutput(self.movieOutput) {
                    captureSession.addOutput(self.movieOutput)
                }
                
                // Configure camera settings
                try videoDevice.lockForConfiguration()
                if self.currentView == "PLR" {
                    videoDevice.videoZoomFactor = 2.0
                }
                if videoDevice.hasTorch{
                    videoDevice.torchMode = .off
                }
                if videoDevice.isFocusModeSupported(.continuousAutoFocus) {
                    videoDevice.focusMode = .continuousAutoFocus
                }
                if videoDevice.isLowLightBoostSupported {
                    videoDevice.automaticallyEnablesLowLightBoostWhenAvailable = true
                }
                //                if videoDevice.isExposureModeSupported(.continuousAutoExposure) {
                //                    videoDevice.exposureMode = .continuousAutoExposure
                //                }
                videoDevice.automaticallyAdjustsVideoHDREnabled = true
                videoDevice.unlockForConfiguration()
                videoOutput.connection(with: .video)?.videoRotationAngle = 90.0
                
                captureSession.commitConfiguration()
                captureSession.startRunning()
                
                DispatchQueue.main.async {
                    self.isSessionReady = true
                }
                
            } catch {
                print("Failed to set up capture session: \(error)")
            }
        }
    }
    
    func saveCurrentExposure() {
        guard let device = videoDevice else { return }
        do {
            try device.lockForConfiguration()
            savedExposureDuration = device.exposureDuration
            savedISO = device.iso
            device.unlockForConfiguration()
            print("Exposure saved: duration \(String(describing: savedExposureDuration)) ISO \(String(describing: savedISO))")
        } catch {
            print("Error saving exposure: \(error.localizedDescription)")
        }
    }
    
    func restoreExposure() {
        guard let device = videoDevice,
              let duration = savedExposureDuration,
              let iso = savedISO else { return }
        do {
            try device.lockForConfiguration()
            device.setExposureModeCustom(duration: duration, iso: iso, completionHandler: nil)
            device.unlockForConfiguration()
            print("Exposure restored to: duration \(duration), ISO \(iso)")
        } catch {
            print("Error restoring exposure: \(error.localizedDescription)")
        }
    }
    
    // Start video recording
    func startRecording() {
        self.irisBoundingBoxes = []
        self.pupilBoundingBoxes = []
        guard let captureSession = captureSession, captureSession.isRunning else {
            print("Capture session is not running.")
            return
        }
        
        // Ensure video connection is active before starting recording
        guard let connection = movieOutput.connection(with: .video), connection.isActive else {
            print("No active video connection.")
            return
        }
        
        let outputURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString).appendingPathExtension("mov")
        self.isRecordingVideo = true
        
        if currentView == "PLR"{
            self.setFlash(on: true, intensity: .leastNonzeroMagnitude)
            DispatchQueue.global(qos: .userInitiated).async {
                while self.videoDevice?.isTorchActive == false {
                    usleep(2000)  // 2 ms delay
                }
                // Once torch is active, start recording on the main thread.
                DispatchQueue.main.async {
                    let outputURL = URL(fileURLWithPath: NSTemporaryDirectory())
                        .appendingPathComponent(UUID().uuidString)
                        .appendingPathExtension("mov")
                    self.isRecordingVideo = true
                    self.movieOutput.startRecording(to: outputURL, recordingDelegate: self)
                }
            }
            self.saveCurrentExposure()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.setFlash(on: true, intensity: 1)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.85) {
                self.restoreExposure()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.setFlash(on: true, intensity: .leastNonzeroMagnitude)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
                self.setFlash(on: false)
                self.stopRecording()
            }
        }else {
            self.movieOutput.startRecording(to: outputURL, recordingDelegate: self)
        }
    }
    
    // Stop video recording
    func stopRecording() {
        if movieOutput.isRecording {
            movieOutput.stopRecording()
        }
        self.isRecordingVideo = false
        setFlash(on: false)
        stopSession()
    }
    
    // Stop the capture session
    func stopSession() {
        sessionQueue.async {
            self.captureSession?.stopRunning()
        }
    }
    
    // Start the capture session
    func startSession() {
        sessionQueue.async {
            if let captureSession = self.captureSession, !captureSession.isRunning {
                captureSession.startRunning()
            }
        }
    }
    
    // Set flash (torch) on/off
    func setFlash(on: Bool, intensity: Float? = nil) {
        guard let videoDevice = self.videoDevice, videoDevice.hasTorch else {
            print("Flash not available on this device.")
            return
        }
        do {
            try videoDevice.lockForConfiguration()
            defer { videoDevice.unlockForConfiguration() }
            
            if on {
                let torchIntensity = intensity ?? 0
                try videoDevice.setTorchModeOn(level: torchIntensity)
            } else {
                videoDevice.torchMode = .off
            }
        } catch {
            print("Failed to set flash: \(error.localizedDescription)")
        }
    }
    
    // Detect eyes in the frame using the CoreML model
    func detectEyes(in ciImage: CIImage) {
        guard let visionModel = visionModel else {
            print("Vision model not loaded")
            return
        }
        
        let request = VNCoreMLRequest(model: visionModel) { request, error in
            if let error = error {
                print("Error detecting eyes: \(error.localizedDescription)")
                return
            }
            
            guard let results = request.results as? [VNRecognizedObjectObservation] else {
                print("No results found")
                DispatchQueue.main.async {
                    self.boundingBox = nil // Clear bounding box if no results
                }
                return
            }
            // Filter results for the "Eye" class
            for observation in results {
                if let topLabel = observation.labels.first {
                    let box = observation.boundingBox
                    if topLabel.identifier == "Eye", topLabel.confidence >= 0.95 && self.currentView == "PLR"{
                        // Update the Eye bounding box on the main thread.
                        DispatchQueue.main.async {
                            self.boundingBox = box
                        }
                    }
                    else if topLabel.identifier == "Iris" && self.isRecordingVideo && self.currentView == "VOMS"{
                        if topLabel.confidence > 0.95 {
                            DispatchQueue.main.async {
                                self.irisBoundingBoxes.append(box)
                            }
                        } else {
                            DispatchQueue.main.async {
                                if !self.irisBoundingBoxes.isEmpty {
                                    self.irisBoundingBoxes.append(self.irisBoundingBoxes[self.irisBoundingBoxes.count - 1])
                                } else {
                                    self.irisBoundingBoxes.append(CGRect.zero)
                                }
                            }
                        }
                    }
                    else if topLabel.identifier == "Pupil" && self.isRecordingVideo && self.currentView == "PLR"{
                        if topLabel.confidence >= 0.9 {
                            DispatchQueue.main.async {
                                self.pupilBoundingBoxes.append(box)
                            }
                        } else {
                            DispatchQueue.main.async {
                                if !self.pupilBoundingBoxes.isEmpty {
                                    self.pupilBoundingBoxes.append(self.pupilBoundingBoxes[self.pupilBoundingBoxes.count - 1])
                                } else {
                                    self.pupilBoundingBoxes.append(CGRect.zero)
                                }
                            }
                        }
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.boundingBox = nil // Clear bounding box if no eye detected
            }
        }
        
        let handler = VNImageRequestHandler(ciImage: ciImage, orientation: .downMirrored, options: [:])
        do {
            try handler.perform([request])
        } catch {
            print("Failed to perform vision request: \(error)")
        }
    }
    
    //overlay Bounding Box for current Image
    func overlayBoundingBox(on image: CIImage, frameIndex: Int, testType: String) -> CIImage {
        var finalImage = image
        var boundingBox: CGRect
        if testType == "PLR"{
            boundingBox = frameIndex < self.pupilBoundingBoxes.count ? self.pupilBoundingBoxes[frameIndex] : CGRect.zero
        }else{
            boundingBox = frameIndex < self.irisBoundingBoxes.count ? self.irisBoundingBoxes[frameIndex] : CGRect.zero
        }
        // Get full image dimensions (should be 1920x1080 in your case).
        let imageWidth = image.extent.width
        let imageHeight = image.extent.height
        
        // Convert normalized boundingBox to pixel coordinates, flipping the y-axis.
        let scaledX = boundingBox.origin.x * imageWidth
        let scaledWidth = boundingBox.size.width * imageWidth
        let scaledHeight = boundingBox.size.height * imageHeight
        let scaledY = imageHeight - (boundingBox.origin.y * imageHeight + scaledHeight)
        
        let overlayRect = CGRect(
            x: scaledX,
            y: scaledY,
            width: scaledWidth,
            height: scaledHeight)
        
        // Create a semi-transparent green overlay for the pupil.
        let overlayColor = CIColor(red: 0, green: 1, blue: 0, alpha: 0.3)
        let boxOverlay = CIImage(color: overlayColor).cropped(to: overlayRect)
        
        // Composite the overlay on top of the original image.
        finalImage = boxOverlay.composited(over: finalImage)
        
        return finalImage
    }
    
    func postProcessing(at url: URL, testType : String, completion: @escaping (URL?) -> Void) {
        let asset = AVAsset(url: url)
        let cropFlag: Bool = testType == "VOMS"
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            completion(nil)
            return
        }
        
        // Define the output URL.
        let outputURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mov
        exportSession.timeRange = CMTimeRange(start: .zero, duration: asset.duration)
        var frameIndex = 0
        
        // Create a video composition that crops each frame.
        let composition = AVMutableVideoComposition(asset: asset) { request in
            let ciImage = request.sourceImage
            let croppedImage = cropFlag ? self.cropImage(on: ciImage.oriented(.right)) : ciImage
            let outputImage = self.overlayBoundingBox(on: croppedImage , frameIndex: frameIndex, testType: testType)
            frameIndex += 1
            request.finish(with: outputImage, context: nil)
        }
        
        // Set the render size to match the cropped output.
        if cropFlag{
            composition.renderSize = CGSize(width: 640, height: 640)
        }
        composition.frameDuration = CMTime(value: 1, timescale: 30)
        
        exportSession.videoComposition = composition
        
        exportSession.exportAsynchronously {
            DispatchQueue.main.async {
                if exportSession.status == .completed {
                    print("Export completed successfully to \(outputURL)")
                    completion(outputURL)
                } else {
                    if let error = exportSession.error {
                        print("Error exporting video: \(error.localizedDescription)")
                    } else {
                        print("Export failed with status: \(exportSession.status.rawValue)")
                    }
                    completion(nil)
                }
            }
        }
    }
    
    // Crop Image
    func cropImage(on image: CIImage) -> CIImage {
        let ciWidth = image.extent.width
        let ciHeight = image.extent.height
        
        // Calculate the center of the image.
        _ = ciWidth / 2
        let centerY = ciHeight / 2
        
        // Define a 640x640 crop rectangle centered on the image.
        let cropRect = CGRect(x: 400,
                              y: centerY - 150,
                              width: 640,
                              height: 640)
        
        // Crop the image to the defined rectangle.
        let croppedImage = image.cropped(to: cropRect)
        
        // Shift the cropped image so that its origin is (0,0).
        let shiftedImage = croppedImage.transformed(by: CGAffineTransform(translationX: -cropRect.origin.x, y: -cropRect.origin.y))
        
        return shiftedImage
    }
    
    // Upload video to server
    func uploadVideoToServer(videoURL: URL, currentView: String) {
        let serverURL = URL(string: uRL)!
        var request = URLRequest(url: serverURL)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let body = NSMutableData()
        
        // Append videoType as a form field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"videoType\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(currentView)\r\n".data(using: .utf8)!)
        
        // Append the file as multipart form data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"videofile\"; filename=\"video.mov\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: video/quicktime\r\n\r\n".data(using: .utf8)!)
        
        // Append the video data
        if let videoData = try? Data(contentsOf: videoURL) {
            body.append(videoData)
        }
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body as Data
        
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 120
        sessionConfig.timeoutIntervalForResource = 120
        let session = URLSession(configuration: sessionConfig)
        
        let task = session.uploadTask(with: request, from: body as Data) { data, response, error in
            if let error = error {
                NotificationCenter.default.post(name: .uploadTimeoutOccurred, object: nil, userInfo: ["message": "\(error.localizedDescription)"])
                print("Error uploading video: \(error)")
            } else if let response = response as? HTTPURLResponse, response.statusCode == 200, let data = data {
                print("Upload successful")
                
                // Parse the JSON response
                do {
                    if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let videoDownloadURL = jsonResponse["video_download_url"] as? String,
                       let graphDownloadURL = jsonResponse["graph_download_url"] as? String {
                        
                        print("Video URL: \(videoDownloadURL)")
                        print("Graph URL: \(graphDownloadURL)")
                        
                        self.handleBackendResponse(videoDownloadURL: videoDownloadURL, graphDownloadURL: graphDownloadURL)
                    }
                } catch {
                    NotificationCenter.default.post(name: .uploadTimeoutOccurred, object: nil, userInfo: ["message": "\(error.localizedDescription)"])
                    print("Failed to parse JSON response: \(error)")
                }
            } else {
                NotificationCenter.default.post(name: .uploadTimeoutOccurred, object: nil, userInfo: ["message": "Upload failed with unexpected response"])
                print("Upload failed with unexpected response")
            }
        }
        task.resume()
    }
    
    // Recieve output from server
    func handleBackendResponse(videoDownloadURL: String, graphDownloadURL: String) {
        if let graphUrl = URL(string: graphDownloadURL){
            DispatchQueue.main.async {
                self.fetchGraph(downloadURL: graphUrl)
            }
        }
        if let videoURL = URL(string: videoDownloadURL) {
            DispatchQueue.main.async {
                self.fetchVideo(downloadURL: videoURL)
            }
        }
    }
    
    // Fetch graph from O/P
    func fetchGraph(downloadURL : URL) {
        let task = URLSession.shared.downloadTask(with: downloadURL) { localURL, response, error in
            if let error = error {
                print("Error fetching graph: \(error.localizedDescription)")
                return
            }
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                print("Failed to fetch graph: Server returned status code \(httpResponse.statusCode)")
                return
            }
            guard let localURL = localURL else {
                print("No graph downloaded")
                return
            }
            
            if let movedURL = self.moveMediaToDocumentsDirectory(localURL, desiredFileName: "graph.png") {
                DispatchQueue.main.async {
                    self.fetchedGraphURL = movedURL
                    print("Graph fetched and moved successfully: \(movedURL)")
                    self.saveGraph(url: movedURL)
                }
            }
        }
        task.resume()
    }
    
    // Fetch video from O/P
    func fetchVideo(downloadURL : URL) {
        let task = URLSession.shared.downloadTask(with: downloadURL) { localURL, response, error in
            if let error = error {
                print("Error fetching video: \(error.localizedDescription)")
                return
            }
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                print("Failed to fetch video: Server returned status code \(httpResponse.statusCode)")
                return
            }
            guard let localURL = localURL else {
                print("No video downloaded")
                return
            }
            
            if let movedURL = self.moveMediaToDocumentsDirectory(localURL, desiredFileName: "video.mp4") {
                DispatchQueue.main.async {
                    self.fetchedVideoURL = movedURL
                    print("Video fetched and moved successfully: \(movedURL)")
                    NotificationCenter.default.post(name: .videoFetched, object: nil)
                    self.saveVideo(url: movedURL)
                }
            }
        }
        task.resume()
    }
    
    // Save recorded video
    func saveVideo(url: URL) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        }) { success, error in
            if let error = error {
                print("Error saving video to photo library: \(error.localizedDescription)")
            } else if success {
                print("Video saved successfully!")
            }
        }
    }
    
    // Save graph
    func saveGraph(url: URL) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: url)
        }) { success, error in
            if let error = error {
                print("Error saving graph to photo library: \(error.localizedDescription)")
            } else if success {
                print("Graph saved successfully!")
            }
        }
    }
    
    // Save O/P media to photo library
    func moveMediaToDocumentsDirectory(_ tempURL: URL, desiredFileName: String = "video.mp4") -> URL? {
        
        let fileManager = FileManager.default
        
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        let uniqueFileName = "\(timestamp)_\(desiredFileName)"
        
        let destinationURL = documentsDirectory.appendingPathComponent(uniqueFileName)
        
        do {
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            
            try fileManager.moveItem(at: tempURL, to: destinationURL)
            
            return destinationURL
        } catch {
            print("Error moving file to documents directory: \(error)")
            return nil
        }
    }
}

// Handle video output sample buffer (frame processing)
extension FrameHandler: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        var ciImage = CIImage(cvPixelBuffer: imageBuffer)
        if self.currentView == "VOMS"{
            ciImage = cropImage(on: ciImage.oriented(.right))
        }
        self.detectEyes(in: ciImage)
        
        DispatchQueue.global(qos: .userInitiated).async {
            guard let cgImage = self.context.createCGImage(ciImage, from: ciImage.extent) else { return }
            DispatchQueue.main.async {
                self.frame = cgImage
            }
        }
    }
}

// Handle video recording delegate
extension FrameHandler: AVCaptureFileOutputRecordingDelegate {
    
    //Handle recorded video before uploading to server
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Error recording video: \(error.localizedDescription)")
        } else {
            postProcessing(at: outputFileURL, testType : self.currentView) { [weak self] processedVidURL in
                guard let self = self else { return }
                print("Post Processing of Video Finished")
                if let processedVidURL = processedVidURL {
                    self.recordedVideoURL = processedVidURL
                    NotificationCenter.default.post(name: .videoRecorded, object: nil)
                    self.saveVideo(url: processedVidURL)
                } else {
                    print("Failed to Post Process video")
                }
            }
            self.saveVideo(url: outputFileURL)
        }
    }
    
}

// Notifications
extension Notification.Name {
    static let videoFetched = Notification.Name("videoFetched")
    static let videoRecorded = Notification.Name("videoRecorded")
    static let uploadTimeoutOccurred = Notification.Name("uploadTimeoutOccurred")
}
