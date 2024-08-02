import AVFoundation
import CoreImage
import Photos
import CoreML
import UIKit

func multiArrayToCGImage(_ multiArray: MLMultiArray) -> CGImage? {
    let pointer = UnsafeMutablePointer<Float>(OpaquePointer(multiArray.dataPointer))
    let width = multiArray.shape[3].intValue
    let height = multiArray.shape[2].intValue
    let channelCount = multiArray.shape[1].intValue
    assert(channelCount == 2) // Assuming two channels output

    let rowBytes = width * 4 // 4 bytes per pixel (RGBA)
    let colorSpace = CGColorSpaceCreateDeviceGray()
    var bitmapInfo: CGBitmapInfo = []
    bitmapInfo.insert(.byteOrder32Little)
    bitmapInfo.insert(CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue))

    guard let context = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: rowBytes,
        space: colorSpace,
        bitmapInfo: bitmapInfo.rawValue
    ) else {
        return nil
    }

    guard let dataPointer = context.data?.assumingMemoryBound(to: UInt8.self) else {
        return nil
    }

    for y in 0..<height {
        for x in 0..<width {
            let pixelIndex = (y * width + x) * channelCount
            let backgroundValue = pointer[pixelIndex]
            let foregroundValue = pointer[pixelIndex + 1]
            
            // Assume foreground is 1 and background is 0, use a threshold
            let maskValue: UInt8 = foregroundValue > backgroundValue ? 255 : 0
            
            let outputPixelIndex = (y * width + x) * 4
            dataPointer[outputPixelIndex] = maskValue
            dataPointer[outputPixelIndex + 1] = maskValue
            dataPointer[outputPixelIndex + 2] = maskValue
            dataPointer[outputPixelIndex + 3] = 255 // Alpha channel
        }
    }

    return context.makeImage()
}



class FrameHandler: NSObject, ObservableObject {
    @Published var frame: CGImage?
    @Published var maskImage: UIImage?
    var captureSession: AVCaptureSession?
    private var permissionGranted = false
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    private let context = CIContext()
    private var movieOutput = AVCaptureMovieFileOutput()
    private var videoDevice: AVCaptureDevice?
    private var model: cyclops_782_1x

    override init() {
        // Initialize the model
        guard let modelURL = Bundle.main.url(forResource: "cyclops_782_1x", withExtension: "mlmodelc") else {
            fatalError("Failed to find model URL.")
        }
        do {
            let model = try cyclops_782_1x(contentsOf: modelURL)
            self.model = model
        } catch {
            fatalError("Failed to load the model: \(error)")
        }

        super.init()
        self.test_model()
        self.checkPermission()
        sessionQueue.async { [unowned self] in
            self.setupCaptureSession()
        }
    }

    func test_model() {
        // Load the image from the app bundle
        guard let image = UIImage(named: "vid28.frame5") else {
            print("Failed to load the image.")
            return
        }
        
        // Convert the UIImage to MLMultiArray
        guard let pixelBuffer = image.toCVPixelBuffer() else {
            print("Failed to convert the image to CVPixelBuffer.")
            return
        }
        
        guard let mlMultiArray = pixelBuffer.toMLMultiArray() else {
            print("Failed to convert CVPixelBuffer to MLMultiArray.")
            return
        }
        
        // Create the model input
        let input = cyclops_782_1xInput(pixel_values: mlMultiArray)
        
        // Make the prediction
        do {
            let output = try model.prediction(input: input)
            let multiArray = output.var_1199
            let width = multiArray.shape[3].intValue
            let height = multiArray.shape[2].intValue
            let channelCount = multiArray.shape[1].intValue
            assert(channelCount == 2) // Assuming two channels output
            
            var predictionArray: [[(Float, Float)]] = Array(repeating: Array(repeating: (0, 0), count: width), count: height)
            
            for y in 0..<height {
                for x in 0..<width {
                    let pixelIndex = (y * width + x) * channelCount
                    let backgroundValue = multiArray[pixelIndex] as! Float
                    let foregroundValue = multiArray[pixelIndex + 1] as! Float
                    predictionArray[y][x] = (backgroundValue, foregroundValue)
                }
            }
            
            // Print the 2D array
            for row in predictionArray {
                print(row)
            }
            
        } catch {
            print("Failed to make a prediction: \(error)")
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
            // Selecting the default dual camera device
            guard let videoDevice = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) else { return }
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            self.videoDevice = videoDevice // Store the video device for zoom and flash control

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
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }

        DispatchQueue.main.async { [unowned self] in
            self.frame = cgImage
        }
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

extension UIImage {
    func toCVPixelBuffer() -> CVPixelBuffer? {
        let width = Int(self.size.width)
        let height = Int(self.size.height)
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
        ] as CFDictionary
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)

        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }

        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        let pixelData = CVPixelBufferGetBaseAddress(buffer)

        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: rgbColorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        )

        context?.translateBy(x: 0, y: CGFloat(height))
        context?.scaleBy(x: 1.0, y: -1.0)

        UIGraphicsPushContext(context!)
        self.draw(in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(buffer, .readOnly)

        return buffer
    }
}

extension CVPixelBuffer {
    func toMLMultiArray() -> MLMultiArray? {
        // Assumes that the pixel buffer format is kCVPixelFormatType_32ARGB
        let width = CVPixelBufferGetWidth(self)
        let height = CVPixelBufferGetHeight(self)
        CVPixelBufferLockBaseAddress(self, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(self, .readOnly) }
        guard let baseAddress = CVPixelBufferGetBaseAddress(self) else { return nil }

        let count = width * height * 3
        guard let mlMultiArray = try? MLMultiArray(shape: [1, 3, NSNumber(value: height), NSNumber(value: width)], dataType: .float32) else { return nil }

        var pixelPointer = baseAddress.assumingMemoryBound(to: UInt8.self)
        var arrayPointer = mlMultiArray.dataPointer.assumingMemoryBound(to: Float32.self)

        for _ in 0..<height {
            for _ in 0..<width {
                let r = Float32(pixelPointer[1]) / 255.0
                let g = Float32(pixelPointer[2]) / 255.0
                let b = Float32(pixelPointer[3]) / 255.0

                arrayPointer.pointee = r
                arrayPointer = arrayPointer.advanced(by: 1)
                arrayPointer.pointee = g
                arrayPointer = arrayPointer.advanced(by: 1)
                arrayPointer.pointee = b
                arrayPointer = arrayPointer.advanced(by: 1)

                pixelPointer = pixelPointer.advanced(by: 4)
            }
        }

        return mlMultiArray
    }
}
