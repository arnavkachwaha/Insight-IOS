//
//  FrameHandler.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 6/25/24.
//

import AVFoundation
import CoreImage
import Photos

class FrameHandler: NSObject, ObservableObject {
    @Published var frame: CGImage?
    var captureSession: AVCaptureSession?
    private var permissionGranted = false
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    private let context = CIContext()
    private var movieOutput = AVCaptureMovieFileOutput()
    private var videoDevice: AVCaptureDevice?
    private var videoUrl: URL?
    var isRecording: Bool = true

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
        captureSession.sessionPreset = .inputPriority
        
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
            try videoDevice.lockForConfiguration()
            videoDevice.focusMode = .continuousAutoFocus
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
            videoDevice.torchMode = .off
            videoDevice.focusMode = .continuousAutoFocus
            if videoDevice.isLowLightBoostSupported{
                videoDevice.automaticallyEnablesLowLightBoostWhenAvailable = true
            }
            videoDevice.automaticallyAdjustsVideoHDREnabled = true
            videoDevice.unlockForConfiguration()
            videoOutput.connection(with: .video)?.videoRotationAngle = 90

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
            self.setFlash(state: false)
            self.isRecording = false
        }
    }

    func saveVideoToPhotos(age: String, sex: String, history: String) {
        guard let videoUrl = self.videoUrl else { return }
        
        // Extract the original file name without the extension
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let dateTimeString = dateFormatter.string(from: Date())
        let fileExtension = videoUrl.pathExtension
        
        // Create a new file name by appending the metadata
        let newFileName = "\(dateTimeString)_\(sex)_\(age)_\(history).\(fileExtension)"
        let newUrl = videoUrl.deletingLastPathComponent().appendingPathComponent(newFileName)
        
        do {
            // Rename the video file by moving it to the new URL
            try FileManager.default.moveItem(at: videoUrl, to: newUrl)
            
            // Save the renamed video to the Photos library
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: newUrl)
            }) { saved, error in
                if let error = error {
                    print("Error saving video to photo library: \(error.localizedDescription)")
                } else if saved {
                    print("Video saved to photo library with name: \(newFileName)")
                }
            }
        } catch {
            print("Error renaming video file: \(error.localizedDescription)")
        }
        
        isRecording = true
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
    func setFlash(state: Bool) {
        guard let videoDevice = self.videoDevice, videoDevice.hasTorch else { return }
        do {
            try videoDevice.lockForConfiguration()
            defer { videoDevice.unlockForConfiguration() }
            
            videoDevice.torchMode = state ? .on : .off
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
            print("Video Recorded at Url: \(outputFileURL.path)")
            videoUrl = outputFileURL
        }
    }
}
