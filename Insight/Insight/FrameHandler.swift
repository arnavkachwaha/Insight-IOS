import AVFoundation
import CoreImage
import Photos
import UIKit
import Combine

class FrameHandler: NSObject, ObservableObject {
    @Published var frame: CGImage?
    var captureSession: AVCaptureSession?
    private var permissionGranted = false
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    private let context = CIContext()
    private var movieOutput = AVCaptureMovieFileOutput()
    private var videoDevice: AVCaptureDevice?
    private let cyclopsProcessor = CyclopsProcessor()
    private var lastFrameTime: CMTime = CMTime.zero

    override init() {
        super.init()
        self.checkPermission()
        sessionQueue.async { [unowned self] in
            self.setupCaptureSession()
        }
    }

    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                self.permissionGranted = true
                self.setupCaptureSession()
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { [unowned self] granted in
                    self.permissionGranted = granted
                    if granted {
                        self.setupCaptureSession()
                    }
                }
            default:
                self.permissionGranted = false
        }
    }

    func setupCaptureSession() {
        guard permissionGranted else { return }

        captureSession = AVCaptureSession()
        guard let captureSession = captureSession else { return }

        captureSession.beginConfiguration()

        do {
            guard let videoDevice = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) else { return }
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            self.videoDevice = videoDevice

            if captureSession.canAddInput(videoDeviceInput) {
                captureSession.addInput(videoDeviceInput)
            }

            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sampleBufferQueue"))
            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
            }

            if captureSession.canAddOutput(movieOutput) {
                captureSession.addOutput(movieOutput)
            }

            captureSession.commitConfiguration()
            captureSession.startRunning()
        } catch {
            print("Failed to set up capture session: \(error)")
        }
    }

    func startRecording() {
        guard let captureSession = captureSession, captureSession.isRunning else { return }
        let outputURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString).appendingPathExtension("mov")
        movieOutput.startRecording(to: outputURL, recordingDelegate: self)
    }

    func stopRecording() {
        if movieOutput.isRecording {
            movieOutput.stopRecording()
        }
    }

    private func saveVideoToPhotos(url: URL) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        }) { saved, error in
            if let error = error {
                print("Error saving video to photo library: \(error.localizedDescription)")
            } else if saved {
                print("Video saved to photo library")
            }
        }
    }

    // Function to set zoom scale
    func setZoom(scale: CGFloat) {
        guard let videoDevice = self.videoDevice else { return }
        do {
            try videoDevice.lockForConfiguration()
            defer { videoDevice.unlockForConfiguration() }

            let zoomFactor = max(1.0, min(scale, videoDevice.activeFormat.videoMaxZoomFactor))
            videoDevice.videoZoomFactor = zoomFactor
        } catch {
            print("Failed to set zoom factor: \(error.localizedDescription)")
        }
    }

    // Function to set flash
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


extension FrameHandler: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Get the current frame timestamp
        let currentTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
        // Throttle the frame processing to 10 FPS
        let frameRate: CMTime = CMTime(value: 1, timescale: 30) // FPS
        if currentTime - lastFrameTime < frameRate {
            return
        }
        lastFrameTime = currentTime
        
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        var ciImage = CIImage(cvPixelBuffer: imageBuffer)
        
        // Rotate the CIImage
        ciImage = ciImage.transformed(by: CGAffineTransform(rotationAngle: -.pi / 2))
        
        // Crop the CIImage to the center 640x480 area
        let croppedImage = cropImageToCenter(ciImage: ciImage, targetSize: CGSize(width: 640, height: 480))
        
        // Apply mask to the cropped CIImage
        let maskedImage = croppedImage //applyMask(to: croppedImage)
        
        guard let cgImage = context.createCGImage(maskedImage, from: maskedImage.extent) else { return }
        
        // Convert CGImage to UIImage (consider optimizing this step by using CGImage directly in your processor)
        let uiImage = UIImage(cgImage: cgImage)

        // Assuming cyclopsProcessor.runModel(on:) returns a tuple with originalImage and outputImage
        let (originalImage, outputImage) = cyclopsProcessor.runModel(on: uiImage)

        // Combine the images
        if let combinedImage = overlayImages(originalImage: originalImage, overlayImage: outputImage!) {
            DispatchQueue.main.async { [unowned self] in
                // Assuming self.frame is of type CGImage, convert combinedImage to CGImage
                if let combinedCGImage = combinedImage.cgImage {
                    self.frame = combinedCGImage
                } else {
                    print("Failed to convert combinedImage to CGImage")
                }
            }
        } else {
            print("Failed to combine images")
        }
    }

    func cropImageToCenter(ciImage: CIImage, targetSize: CGSize) -> CIImage {
        // Calculate the center rectangle
        let centerX = ciImage.extent.midX
        let centerY = ciImage.extent.midY
        
        let cropRect = CGRect(
            x: centerX - targetSize.width / 2,
            y: centerY - targetSize.height / 2,
            width: targetSize.width,
            height: targetSize.height
        )
        
        // Crop the image to the center rectangle
        return ciImage.cropped(to: cropRect)
    }


    // Function to create and apply a mask
    func applyMask(to image: CIImage) -> CIImage {
        // Define the mask size to cover a portion of the cropped image
        let maskRect = CGRect(x: 220, y: 120, width: 200, height: 200) // Example mask rect centered within the 640x480 cropped image
        let maskImage = CIImage(color: CIColor(red: 1.0, green: 0, blue: 0, alpha: 0.5)).cropped(to: maskRect)
        
        // Combine the original image and the mask
        let maskedImage = maskImage.composited(over: image)
        
        return maskedImage
    }
    
    func overlayImages(originalImage: UIImage, overlayImage: UIImage) -> UIImage? {
        // Start with the size of the original image
        let size = originalImage.size
        
        // Begin a new image context, to draw the images onto
        UIGraphicsBeginImageContextWithOptions(size, false, originalImage.scale)
        
        // Draw the original image as the background
        originalImage.draw(in: CGRect(origin: .zero, size: size))
        
        // Draw the overlay image on top of the original image
        overlayImage.draw(in: CGRect(origin: .zero, size: size))
        
        // Capture the result as a new UIImage
        let combinedImage = UIGraphicsGetImageFromCurrentImageContext()
        
        // End the image context
        UIGraphicsEndImageContext()
        
        return combinedImage
    }


}

extension FrameHandler: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Error recording Video: \(error.localizedDescription)")
        } else {
            print("Video Recording saved at: \(outputFileURL.path)")
            saveVideoToPhotos(url: outputFileURL)
        }
    }
}
