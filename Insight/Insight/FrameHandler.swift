//
//  FrameHandler.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 6/25/24.
//

import AVFoundation
import CoreImage
import Photos
import SwiftUI

class FrameHandler: NSObject, ObservableObject {
    @Published var frame: CGImage?
    var captureSession: AVCaptureSession?
    private var permissionGranted = false
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    private let context = CIContext()
    private var movieOutput = AVCaptureMovieFileOutput()
    private var videoDevice: AVCaptureDevice?
    @Published var currentView = "PLR"
    @Published var recordedVideoURL: URL?
    @Published var fetchedVideoURL: URL?
    @Published var fetchedGraphURL: URL?
    @Published var isSessionReady = false
    @Published var uRL = "http://10.243.79.16:8000/cyclops/upload/"
    
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

    // Setup camera session
    func setupCaptureSession() {
        guard permissionGranted else { return }

        sessionQueue.async {
            self.captureSession = AVCaptureSession()
            guard let captureSession = self.captureSession else { return }

            captureSession.beginConfiguration()
            captureSession.sessionPreset = .inputPriority
            
            do {
                // Get video device (back camera)
                guard let videoDevice = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) else { return }
                let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
                self.videoDevice = videoDevice

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
                var selectedFormat: AVCaptureDevice.Format?
                var selectedFrameRateRange: AVFrameRateRange?
                let desiredResolution = CMVideoDimensions(width: 1920, height: 1080)

                for format in videoDevice.formats {
                    let formatDescription = format.formatDescription
                    let resolution = CMVideoFormatDescriptionGetDimensions(formatDescription)

                    if resolution.width == desiredResolution.width && resolution.height == desiredResolution.height {
                        let frameRateRanges = format.videoSupportedFrameRateRanges

                        for range in frameRateRanges {
                            if range.maxFrameRate >= 60 && range.minFrameRate <= 60 {
                                selectedFormat = format
                                selectedFrameRateRange = range
                                break
                            }
                        }

                        if selectedFormat != nil {
                            break
                        }
                    }
                }

                if let selectedFormat = selectedFormat, let frameRateRange = selectedFrameRateRange {
                    videoDevice.activeFormat = selectedFormat
                    videoDevice.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: Int32(frameRateRange.maxFrameRate))
                    videoDevice.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: Int32(frameRateRange.maxFrameRate))
                } else {
                    print("No format supports 60 fps at the desired resolution.")
                }
                videoDevice.videoZoomFactor = 2.0
                videoDevice.torchMode = .off
//                videoDevice.focusMode = .continuousAutoFocus
//                videoDevice.whiteBalanceMode = .autoWhiteBalance
//                videoDevice.automaticallyEnablesLowLightBoostWhenAvailable = true
                videoDevice.automaticallyAdjustsVideoHDREnabled = true
                videoDevice.unlockForConfiguration()

                videoOutput.connection(with: .video)?.videoRotationAngle = 90

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

    // Save recorded video to photo library
    func saveVideoToPhotos(url: URL) {
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
    
    func saveGraphToPhotos(url: URL) {
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
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Error recording video: \(error.localizedDescription)")
        } else {
            recordedVideoURL = outputFileURL
            NotificationCenter.default.post(name: .videoRecorded, object: nil)
        }
    }
    
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
                    print("Failed to parse JSON response: \(error)")
                }
            } else {
                print("Upload failed with unexpected response")
            }
        }
        task.resume()
    }

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
                    self.saveGraphToPhotos(url: movedURL)
                }
            }
        }
        task.resume()
    }
    
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
                    self.saveVideoToPhotos(url: movedURL)
                }
            }
        }
        task.resume()
    }

    func moveMediaToDocumentsDirectory(_ tempURL: URL, desiredFileName: String = "video.mp4") -> URL? {

        let fileManager = FileManager.default

        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!

        let destinationURL = documentsDirectory.appendingPathComponent(desiredFileName)

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

extension Notification.Name {
    static let videoFetched = Notification.Name("videoFetched")
    static let videoRecorded = Notification.Name("videoRecorded")
}
