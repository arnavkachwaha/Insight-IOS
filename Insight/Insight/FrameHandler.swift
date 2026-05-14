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
    @Published var recordedVideoURL: URL?
    @Published var processedVideoURL: URL?
    @Published var isSessionReady = false
    @Published var imgSize: CGSize = .zero
    @Published var currentView: String = ""
    @Published var plotData: [Double] = []
    @Published var irisBoundingBoxes: [CGRect] = []
    @Published var pupilBoundingBoxes: [CGRect] = []
    @Published var captureSession: AVCaptureSession?
    
    override init() {
        super.init()
        loadModel()
        checkPermission()
    }
    
    func loadModel() {
        do {
            let model = try EyeDetector(configuration: MLModelConfiguration()).model
            visionModel = try VNCoreMLModel(for: model)
            print("Model loaded successfully")
        } catch {
            print("Failed to load model: \(error)")
        }
    }
    
    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionGranted = true
            setupCaptureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [unowned self] granted in
                self.permissionGranted = granted
                if granted { self.setupCaptureSession() }
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
                // Determine camera based on currentView
                let deviceTypes: [AVCaptureDevice.DeviceType] = [.builtInUltraWideCamera, .builtInWideAngleCamera, .builtInDualWideCamera, .builtInTelephotoCamera, .builtInDualCamera, .builtInTripleCamera]
                let position: AVCaptureDevice.Position = (self.currentView == "VOMS") ? .front : .back
                
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
                
                // Configure device settings
                try videoDevice.lockForConfiguration()
                if self.currentView == "PLR" {
                    videoDevice.videoZoomFactor = 2.0
                }
                if videoDevice.hasTorch { videoDevice.torchMode = .off }
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
                
                DispatchQueue.main.async { self.isSessionReady = true }
                
            } catch {
                print("Failed to set up capture session: \(error)")
            }
        }
    }
    
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
    
    func stopRecording() {
        if movieOutput.isRecording {
            movieOutput.stopRecording()
        }
        self.isRecordingVideo = false
        setFlash(on: false)
        stopSession()
    }
    
    func stopSession() {
        sessionQueue.async { self.captureSession?.stopRunning() }
    }
    
    func startSession() {
        sessionQueue.async {
            if let captureSession = self.captureSession, !captureSession.isRunning {
                captureSession.startRunning()
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
    
    func setFlash(on: Bool, intensity: Float? = 1.0) {
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
    
    // MARK: - Eye Detection
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
                        DispatchQueue.main.async { self.boundingBox = nil }
                        return
                    }
                    for observation in results {
                        if let topLabel = observation.labels.first {
                            let box = observation.boundingBox
                            if topLabel.identifier == "Eye", topLabel.confidence >= 0.95 {
                                DispatchQueue.main.async { self.boundingBox = box }
                            }
                            else if topLabel.identifier == "Iris" && self.isRecordingVideo{
                                let updatedBox = topLabel.confidence > 0.95 ? box : (self.irisBoundingBoxes.last ?? CGRect.zero)
                                DispatchQueue.main.async { self.irisBoundingBoxes.append(updatedBox) }
                            }
                            else if topLabel.identifier == "Pupil" && self.isRecordingVideo && self.currentView == "PLR" {
                                let irisBoundingBox = self.irisBoundingBoxes.last ?? CGRect.zero
                                let updatedBox = (topLabel.confidence >= 0.9 && irisBoundingBox.contains(box)) ? box : (self.pupilBoundingBoxes.last  ?? CGRect.zero)
                                DispatchQueue.main.async { self.pupilBoundingBoxes.append(updatedBox) }
                            }
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.boundingBox = nil // Clear if no eye detected
                    }
                }
                
                let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
                do {
                    try handler.perform([request])
                } catch {
                    print("Failed to perform vision request: \(error)")
                }


//            if let pupilObs = pupilObservation, self.isRecordingVideo, self.currentView == "PLR" {
//                let pupilBox = pupilObs.boundingBox
//                let pupilConfidence = pupilObs.labels.first?.confidence ?? 0
//                
//                // A pupil detection is valid only if confidence is high AND it's inside the iris box.
//                let isPupilValid = pupilConfidence >= 0.87 && currentIrisBox.contains(pupilBox)
//                
//                let updatedPupilBox = isPupilValid ? pupilBox : (self.pupilBoundingBoxes.last ?? .zero)
//                
//                DispatchQuetxtue.main.async {
//                    self.pupilBoundingBoxes.append(updatedPupilBox)
//                }
//            }
//        }

    }
    
    // MARK: -  Processing
    func processRecordedVideo(at url: URL) {
        // Convert normalized bounding boxes to pixel coordinates.
        DispatchQueue.main.async {
            self.irisBoundingBoxes = self.irisBoundingBoxes.map {
                Helper.convertNormalizedBoxToPixel(boundingBox: $0, imageSize: self.imgSize)
            }
            self.pupilBoundingBoxes = self.pupilBoundingBoxes.map {
                Helper.convertNormalizedBoxToPixel(boundingBox: $0, imageSize: self.imgSize)
            }
            
            Helper.processRecordedVideo(
                at: url,
                testType: self.currentView,
                imageSize: self.imgSize,
                irisBoundingBoxes: self.irisBoundingBoxes,
                pupilBoundingBoxes: self.pupilBoundingBoxes
            ) { [weak self] processedVidURL, plotData in
                guard let self = self else { return }
                print("Post Processing of Video Finished")
                if let processedVidURL = processedVidURL, let plotData = plotData {
                    self.processedVideoURL = processedVidURL
                    self.plotData = plotData
                    
                    Helper.saveVideo(url: processedVidURL)
                    NotificationCenter.default.post(name: .videoProcessed, object: processedVidURL)
                } else {
                    print("Failed to post process video")
                }
            }
        }
    }
    
    func getPlrMetrics(frameRadius: [Double]) -> (maxPD: Double, minPD: Double, latency: String, maxConstriction: Double, seventyFivePercentRecovery: String, adv: Double, acv: Double) {
        // a fallback ratio just in case the iris wasn't detected
        var dynamicMmPerPixel: Double = 0.108
        
        // Calculate the dynamic ratio based on 11.7mm average human iris
        
        if !self.irisBoundingBoxes.isEmpty {
            // Get the sum of all detected iris widths
            let totalIrisWidth = self.irisBoundingBoxes.reduce(0) { $0 + $1.width }
            // Find the average pixel width of the iris across the video
            let avgIrisWidthPx = totalIrisWidth / Double(self.irisBoundingBoxes.count)
            // Divide standard anatomical iris size (11.7mm) by the pixel width
            dynamicMmPerPixel = 11.7 / avgIrisWidthPx
            print("Calculated Dynamic mm/pixel ratio: \(dynamicMmPerPixel)")
        } else {
            print("Warning: No iris bounding boxes found. Using fallback ratio.")
        }
        return RadiusDataProcessor.getPlrMetrics(frameRadius: frameRadius, fps: 30.0, mmPerPixel: dynamicMmPerPixel)
    }

}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension FrameHandler: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        var ciImage = CIImage(cvPixelBuffer: imageBuffer)
        if self.currentView == "VOMS" {
            ciImage = Helper.cropImage(on: ciImage.oriented(.right))
        }
        self.detectEyes(in: ciImage)
        if self.imgSize == .zero{
            DispatchQueue.main.async {
                self.imgSize = CGSize(width: ciImage.extent.width, height: ciImage.extent.height)
            }
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            guard let cgImage = self.context.createCGImage(ciImage, from: ciImage.extent) else { return }
            DispatchQueue.main.async { self.frame = cgImage }
        }
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate
extension FrameHandler: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput,
                    didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection],
                    error: Error?) {
        if let error = error {
            print("Error recording video: \(error.localizedDescription)")
        } else {
            self.recordedVideoURL = outputFileURL
            Helper.saveVideo(url: outputFileURL)
            NotificationCenter.default.post(name: .videoRecorded, object: outputFileURL)
            
            // Call the post-processing helper function.
            self.processRecordedVideo(at: outputFileURL)
        }
    }
}

// MARK: - Notifications
extension Notification.Name {
    static let graphFetched = Notification.Name("graphFetched")
    static let videoRecorded = Notification.Name("videoRecorded")
    static let videoProcessed = Notification.Name("videoProcessed")
    static let uploadTimeoutOccurred = Notification.Name("uploadTimeoutOccurred")
}
