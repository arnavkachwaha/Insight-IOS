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
    var captureSession: AVCaptureSession?
    private var permissionGranted = false
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    private let context = CIContext()
    private var movieOutput = AVCaptureMovieFileOutput()
    private var videoDevice: AVCaptureDevice?
    @Published var currentView: String = "PLR" 
    @Published var recordedVideoURL: URL?
    @Published var fetchedVideoURL: URL?
    @Published var fetchedGraphURL: URL?
    @Published var isSessionReady = false
    @Published var frame: CGImage?
    @Published var uRL = "http://a8a175088b809630c.awsglobalaccelerator.com:8000/cyclops/upload/"
    //    @Published var uRL = "http://10.243.79.16:8000/cyclops/upload/"
    var lastFrameTime: CMTime = CMTimeMake(value: 0, timescale: 1)

    var previewView: UIView? // Add a reference to the view
    var player: AVPlayer?
    var playerItemVideoOutput: AVPlayerItemVideoOutput?
    private var isProcessingFrame = false
    var boundingBoxRect: CGRect? {
        didSet {
            // Notify the view controller when bounding box updates
            onBoundingBoxUpdated?(boundingBoxRect)
        }
    }
    
    var onBoundingBoxUpdated: ((CGRect?) -> Void)?
    
    override init() {
        super.init()
        checkPermission()
        
        // mock bounding box at top left corner
        boundingBoxRect = CGRect(x:0, y: 0, width: 100, height: 100)
        
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
            
            #if targetEnvironment(simulator)
            // Running on simulator: use local video file
            guard let videoURL = Bundle.main.url(forResource: "plr_1", withExtension: "mp4") else {
                print("Video file not found")
                return
            }
            print("videoURL: ", videoURL)
            let playerItem = AVPlayerItem(url: videoURL)
            self.player = AVPlayer(playerItem: playerItem)
            
            
            let videoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
            ])
            playerItem.add(videoOutput)
            self.playerItemVideoOutput = videoOutput
            
            // Start playing the video
            self.player?.play()
            
            // Use a display link to get video frames
            let displayLink = CADisplayLink(target: self, selector: #selector(self.displayLinkDidRefresh))
            displayLink.add(to: .main, forMode: .default)

            DispatchQueue.main.async {
                self.isSessionReady = true
            }

            #else
            // Running on device: use camera input
            do {
                // Get video device (back camera)
                // TODO: iphone XS did not get builtInDualWideCamera.
                // TODO: look into camera swithing
                guard let videoDevice = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) else {
                    print("Cannot get videoDevice")
                    return
                }
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
                videoDevice.videoZoomFactor = 2.25
                videoDevice.torchMode = .off
                videoDevice.focusMode = .continuousAutoFocus
                if videoDevice.isLowLightBoostSupported {
                    videoDevice.automaticallyEnablesLowLightBoostWhenAvailable = true
                }
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
            #endif
        }
    }

    @objc func displayLinkDidRefresh() {
        guard let videoOutput = playerItemVideoOutput, let player = player else {
            print("Player or video output not set up.")
            return
        }
        
        // Get the current playback time
        let currentTime = player.currentTime()
        
        // Check if there's a new pixel buffer for the current time
        if videoOutput.hasNewPixelBuffer(forItemTime: currentTime) {
//            print("Frame available for time: \(currentTime)")
            
            // Retrieve the pixel buffer
            if let pixelBuffer = videoOutput.copyPixelBuffer(forItemTime: currentTime, itemTimeForDisplay: nil) {
                // Convert to a CGImage for rendering or processing
                let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
                if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
                    DispatchQueue.main.async {
                        self.frame = cgImage
                    }
                }
                
                self.checkForIrisFrame(pixelBuffer: pixelBuffer, currentTime: currentTime)
            }
        } else {
            print("No frame: \(currentTime)")
            lastFrameTime = .zero
            self.player?.seek(to: .zero)
            self.player?.play()
        }
    }
    
    // Rotate the UIImage 90 degrees clockwise
    func rotateImage90DegreesClockwise(_ image: UIImage) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: image.size.height, height: image.size.width))
        return renderer.image { context in
            let cgContext = context.cgContext
            
            // Translate and rotate the context
            cgContext.translateBy(x: image.size.height / 2, y: image.size.width / 2)
            cgContext.rotate(by: .pi / 2) // Rotate 90 degrees clockwise
            
            // Draw the image centered at (0, 0) with flipped y-axis
            cgContext.translateBy(x: -image.size.width / 2, y: -image.size.height / 2)
            image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        }
    }
    
    // Crop the top half of the frame to send to iris detector
    // note this is not the same as video cropping logic
    func cropTopHalf(_ image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        
        // Account for the scale of the UIImage (e.g., Retina display)
        let scale = image.scale
        let pixelHeight = CGFloat(cgImage.height) // Height in pixels
        let pixelWidth = CGFloat(cgImage.width)  // Width in pixels

        // Define the cropping rectangle in pixel dimensions
        let cropRect = CGRect(x: 0, y: 0, width: pixelWidth, height: pixelHeight / 2)

        // Perform the cropping
        guard let croppedCgImage = cgImage.cropping(to: cropRect) else { return nil }
        
        // Convert back to UIImage, ensuring the same scale
        return UIImage(cgImage: croppedCgImage, scale: scale, orientation: image.imageOrientation)
    }
    
    func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage? {
        // Get the scale factor of the image (e.g., for Retina displays, it could be 2.0 or 3.0)
        // TODO: fix scaling issue. image.scale is = 0.5. Need 1/ scale for conversion. But should be 0.33
        // need to study pixel vs points and retina screens 
        let scale = 0.33333

        // Adjust target size based on the scale factor to ensure the target size is in pixels
        let targetSizeInPixels = CGSize(width: targetSize.width * scale, height: targetSize.height * scale)

        // Use the adjusted target size to resize the image
        let renderer = UIGraphicsImageRenderer(size: targetSizeInPixels)
        return renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: targetSizeInPixels))
        }
    }
    
    func checkForIrisFrame(pixelBuffer: CVPixelBuffer, currentTime: CMTime) {
        let elapsedTime = CMTimeSubtract(currentTime, lastFrameTime)

//        print("lastFrameTime: ", CMTimeGetSeconds(lastFrameTime))
//        print("elapsedTime: ", CMTimeGetSeconds(elapsedTime))

        // Wait until the last frame has been processed and time condition is met
        // TODO: fix elapsed time issue. should only really matter for video asset not live camera
        if !isProcessingFrame && (CMTimeGetSeconds(lastFrameTime) == 0 || CMTimeGetSeconds(elapsedTime) >= 3.0) {
            isProcessingFrame = true // Set the processing state
            lastFrameTime = currentTime
            print("Processing new frame. Updated lastFrameTime: \(CMTimeGetSeconds(lastFrameTime))")
            
            // get ciImage from buffer
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)

            DispatchQueue.global(qos: .userInitiated).async {
                guard let cgImage = self.context.createCGImage(ciImage, from: ciImage.extent) else {
                    print("Failed to create CGImage.")
                    self.isProcessingFrame = false // Reset the state on failure
                    return
                }

                // Convert CGImage to UIImage
                var uiImage = UIImage(cgImage: cgImage)

                // Rotate the UIImage 90 degrees clockwise
                #if targetEnvironment(simulator)
                if let rotatedUIImage = self.rotateImage90DegreesClockwise(uiImage) {
                    uiImage = rotatedUIImage
                } else {
                    print("Failed to rotate the image. Aborting capture.")
                    self.isProcessingFrame = false // Reset the state on failure
                    return
                }
                #endif

                // TODO: Crop top half
                // Crop the top half of the rotated image
                if let croppedUIImage = self.cropTopHalf(uiImage) {
                    // Print height and width of the cropped image
                    print("Cropped Height: \(croppedUIImage.size.height), Cropped Width: \(croppedUIImage.size.width)")
                    
                    uiImage = croppedUIImage

                } else {
                    print("Failed to crop the image. Aborting capture.")
                    self.isProcessingFrame = false // Reset the state on failure
                    return
                }

                // Print height and width of the cropped image
                print("Height: \(uiImage.size.height), Width: \(uiImage.size.width)")
                
                // resize Image
                let resizedImage = self.resizeImage(uiImage, targetSize: CGSize(width: 1080, height: 810))
                if let resizedImage = resizedImage {
                    print("Resized Height: \(resizedImage.size.height), Resized Width: \(resizedImage.size.width)")

                    // Upload JPEG data to API
                    self.uploadJPEGToAPI(resizedImage)

                } else {
                    print("Failed to resize the image. Aborting capture.")
                }
            }
        } else {
//            print("Skipping frame. Either still processing or time hasn't elapsed.")
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

// Handle video output sample buffer and check for iris 
extension FrameHandler: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let currentTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
          
        self.checkForIrisFrame(pixelBuffer: imageBuffer, currentTime: currentTime)
      }
      
      func uploadJPEGToAPI(_ uiImage: UIImage) {
        // Load Image and Convert to Base64
          let imageData = uiImage.jpegData(compressionQuality: 1.0)
        let fileContent = imageData?.base64EncodedString()
        let postData = fileContent!.data(using: .utf8)
          
      // Convert to JPEG data
//      if let imageData = uiImage.jpegData(compressionQuality: 1.0) {
//          // Define the file name
//          let fileName = "image.jpeg"
//          
//          // Get the path to the app's Documents directory
//          let fileManager = FileManager.default
//          let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
//          let fileURL = documentsURL.appendingPathComponent(fileName)
//          
//          do {
//              // Save the image data to the Documents directory
//              try imageData.write(to: fileURL)
//              print("File saved locally in Documents at: \(fileURL)")
//          } catch {
//              print("Error saving file: \(error.localizedDescription)")
//          }
//      }

        // Initialize Inference Server Request with API KEY, Model, and Model Version
        var request = URLRequest(url: URL(string: "https://detect.roboflow.com/video1-ba4g1/2?api_key=rsXNxxW9CvcYI9TSLFpu&name=YOUR_IMAGE.jpg&confidence=20")!,timeoutInterval: Double.infinity)
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = postData

        print("Sending Image to Inference Server...")
        // Execute Post Request
        URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in

            // Parse Response to String
            guard let data = data else {
                print(String(describing: error))
                return
            }
            
            print("Retrieved response from Inference Server...")

            // Convert Response String to Dictionary
            do {
                let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }

            // Print String Response
            print(String(data: data, encoding: .utf8)!)
            self.processPredictions(responseData: data)
        }).resume()
      }
    

    func processPredictions(responseData: Data) {
        // Parse JSON Data
        do {
            let json = try JSONSerialization.jsonObject(with: responseData, options: []) as! [String: Any]

            if let predictions = json["predictions"] as? [[String: Any]] {
                if predictions.isEmpty {
                    self.isProcessingFrame = false
                    return
                }
                if predictions[0]["class"] as! String == "iris" {
                    let confidence = predictions[0]["confidence"] as! Double
                    let x = predictions[0]["x"] as! Double
                    let y = predictions[0]["y"] as! Double
                    let width = predictions[0]["width"] as! Double
                    let height = predictions[0]["height"] as! Double
                    
                    // Print Iris Prediction
                    print("IRIS: ", confidence, x, y, width, height)
                    
                    // Update bounding box
                    DispatchQueue.main.async {
                        
                        // TODO: fix this distaster
                        var x = x / 3
                        var y = y / 3
                        var width = width / 3
                        var height = height / 3
                        
                        x = x - width / 2
                        y = y + height
                        width = width
                        height = height
                                          
                        self.updateBoundingBox(x: x, y: y, width: width, height: height)
                        // Mark processing as complete
                        self.isProcessingFrame = false
                    }
                }
            }
            else {
                print("Error: 'predictions' is either nil or not in the expected format.")
                // Mark processing as complete
                self.isProcessingFrame = false
                return
            }
        } catch {
            print(error.localizedDescription)
        }
    }

    func updateBoundingBox(x: Double, y: Double, width: Double, height: Double) {
        // Update the bounding box rect
        boundingBoxRect = CGRect(x: x, y: y, width: width, height: height)
    }
    
}

// Handle video recording delegate
extension FrameHandler: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Error recording video: \(error.localizedDescription)")
        } else {
            // Crop the video after recording
            cropVideo(at: outputFileURL) { [weak self] croppedURL in
                guard let self = self else { return }
                print("cropVideo finished")
                if let croppedURL = croppedURL {
                    // Save or use the cropped URL as needed
                    self.recordedVideoURL = croppedURL
                    
                    // Notify that the cropped video is ready
                    NotificationCenter.default.post(name: .videoRecorded, object: nil)
                    
                    // Optionally save to Photos
                    self.saveVideoToPhotos(url: croppedURL)
                } else {
                    print("Failed to crop video")
                }
            }
        }
    }
    
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
        sessionConfig.timeoutIntervalForRequest = 60
        sessionConfig.timeoutIntervalForResource = 60
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
    static let uploadTimeoutOccurred = Notification.Name("uploadTimeoutOccurred")
}
