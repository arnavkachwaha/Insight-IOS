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
    private let context = CIContext()
    private var permissionGranted = false
    var captureSession: AVCaptureSession?
    private var videoDevice: AVCaptureDevice?
    private var movieOutput = AVCaptureMovieFileOutput()
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    
    @Published var frame: CGImage?
    @Published var fetchedVideoURL: URL?
    @Published var fetchedGraphURL: URL?
    @Published var recordedVideoURL: URL?
    @Published var isSessionReady = false
    @Published var currentView: String = ""
    @Published var uRL = "http://a8a175088b809630c.awsglobalaccelerator.com:8000/cyclops/upload/"
    //    @Published var uRL = "http://192.168.4.108:8000/cyclops/upload/" //local server
    
    override init() {
        super.init()
        checkPermission()
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
            captureSession.sessionPreset = .high // Adjust as needed
            
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
                position = .back
                
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
                videoDevice.torchMode = .off
                videoDevice.focusMode = .continuousAutoFocus
                if videoDevice.isLowLightBoostSupported {
                    videoDevice.automaticallyEnablesLowLightBoostWhenAvailable = true
                }
                videoDevice.automaticallyAdjustsVideoHDREnabled = true
                videoDevice.unlockForConfiguration()
                
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
    
    // Start video recording
    func startRecording() {
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
        movieOutput.startRecording(to: outputURL, recordingDelegate: self)
        
        if currentView == "PLR"{
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.setFlash(on: true)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.setFlash(on: false)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 6.25) {
                self.stopRecording()
            }
        }
    }
    
    // Stop video recording
    func stopRecording() {
        if movieOutput.isRecording {
            movieOutput.stopRecording()
        }
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
    func setFlash(on: Bool) {
        guard let videoDevice = self.videoDevice, videoDevice.hasTorch else { return }
        do {
            try videoDevice.lockForConfiguration()
            defer { videoDevice.unlockForConfiguration() }
            
            videoDevice.torchMode = on ? .on : .off
        } catch {
            print("Failed to set flash: \(error.localizedDescription)")
        }
    }
}

// Handle video output sample buffer (frame processing)
extension FrameHandler: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        
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
            if self.currentView == "VOMS"{
                self.recordedVideoURL = outputFileURL
                // Notify that the  video is ready
                NotificationCenter.default.post(name: .videoRecorded, object: nil)
                
                // Optionally save video
                self.saveVideo(url: outputFileURL)
            }
            else{
                // Crop the video after recording for PLR
                cropVideo(at: outputFileURL) { [weak self] croppedURL in
                    guard let self = self else { return }
                    print("cropVideo finished")
                    if let croppedURL = croppedURL {
                        // Save or use the cropped URL as needed
                        self.recordedVideoURL = croppedURL
                        
                        // Notify that the cropped video is ready
                        NotificationCenter.default.post(name: .videoRecorded, object: nil)
                        
                        // Optionally save videp
                        self.saveVideo(url: croppedURL)
                    } else {
                        print("Failed to crop video")
                    }
                }
            }
        }
    }
    
    // Crop video
    func cropVideo(at url: URL, completion: @escaping (URL?) -> Void) {
        // Run the cropping process on a background thread
        let asset = AVAsset(url: url)
        
        let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)
        
        // Define the output URL
        let outputURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString).appendingPathExtension("mov")
        exportSession?.outputURL = outputURL
        exportSession?.outputFileType = .mov
        exportSession?.timeRange = CMTimeRange(start: .zero, duration: asset.duration)
        //        exportSession?.shouldOptimizeForNetworkUse = true
        
        // Create a composition and set the render size to 640x480
        let composition = AVMutableVideoComposition(asset: asset) { request in
            print("Running crop composition")
            
            let ciImage = request.sourceImage
            let ciHeight = ciImage.extent.height
            let ciWidth = ciImage.extent.width
            
            // Define the crop area (you can adjust this crop size)
            let cropHeight = ciWidth * 0.75
            let cropRect = CGRect(x: 0, y: ciHeight - cropHeight, width: ciWidth, height: cropHeight)
            let croppedImage = ciImage.cropped(to: cropRect)
            
            // reize image to 640x480
            let scaleFactor: CGFloat = 640.0 / ciWidth
            let scaledImage = croppedImage.transformed(by: CGAffineTransform(scaleX: scaleFactor, y: scaleFactor))
            
            // Translate the final image down to focus on the top part of the image
            let translateY = 659.0
            let translateTransform = CGAffineTransform(translationX: 0, y: -translateY)
            let translatedImage = scaledImage.transformed(by: translateTransform)
            
            // Finish the request with the translated image
            request.finish(with: translatedImage, context: nil)
            
        }
        
        // Set the renderSize to match the desired output size (e.g., 640x480)
        composition.renderSize = CGSize(width: 640, height: 480)
        
        exportSession?.videoComposition = composition
        
        // Ensure exportSession is properly initialized
        guard let exportSession = exportSession else {
            print("Export session is nil")
            completion(nil)
            return
        }
        // Check the export session's status before starting
        if exportSession.status == .waiting || exportSession.status == .unknown {
            print("exportSession Status", exportSession.status.rawValue)
            // Start exporting
            exportSession.exportAsynchronously {
                // Once the export finishes, execute the completion handler on the main thread
                DispatchQueue.main.async {
                    if exportSession.status == .completed {
                        print("Export completed successfully")
                        completion(outputURL)
                    } else if let error = exportSession.error {
                        print("Error exporting video: \(error.localizedDescription)")
                        completion(nil)
                    } else {
                        print("Export failed with status: \(exportSession.status.rawValue)")
                        completion(nil)
                    }
                }
            }
        } else {
            print("Export session is not in a valid state to start exporting: \(exportSession.status.rawValue)")
            completion(nil)
        }
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

// Notifications
extension Notification.Name {
    static let videoFetched = Notification.Name("videoFetched")
    static let videoRecorded = Notification.Name("videoRecorded")
    static let uploadTimeoutOccurred = Notification.Name("uploadTimeoutOccurred")
}
