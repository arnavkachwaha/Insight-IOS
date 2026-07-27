//
//  Helper.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 3/28/25.
//

import UIKit
import CoreImage
import AVFoundation
import Photos

struct Helper {
    
    static func cropImage(on image: CIImage) -> CIImage {
        let imageWidth = image.extent.width
        let imageHeight = image.extent.height
        let cropSize: CGFloat = 640.0
        
        // Center horizontally
        let cropX = (imageWidth - cropSize) / 2.0
        // Match the vertical alignment of the UI Eye Cutout
        let cropY = (imageHeight / 2) - 145
        let cropRect = CGRect(x: cropX, y: cropY, width: cropSize, height: cropSize)
        let croppedImage = image.cropped(to: cropRect)
        
        // Shift origin back to (0,0)
        let shiftedImage = croppedImage.transformed(by: CGAffineTransform(translationX: -cropRect.origin.x, y: -cropRect.origin.y))
        return shiftedImage
    }
    
    // In Helper.swift
    static func convertNormalizedBoxToPixel(boundingBox: CGRect, imageSize: CGSize) -> CGRect {
        let x = boundingBox.origin.x * imageSize.width
        let y = (1 - boundingBox.origin.y - boundingBox.height) * imageSize.height
        let width = boundingBox.width * imageSize.width
        let height = boundingBox.height * imageSize.height
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    static func overlayBoundingBox(on image: CIImage,
                                   frameIndex: Int,
                                   testType: String,
                                   imageSize: CGSize,
                                   irisBoundingBoxes: [CGRect],
                                   pupilBoundingBoxes: [CGRect],
                                   radii: [Double]) -> CIImage {
        var finalImage = image
        var boundingBox: CGRect = .zero

        if testType == "PLR" {
            boundingBox = frameIndex < pupilBoundingBoxes.count ? pupilBoundingBoxes[frameIndex] : .zero
        } else {
            boundingBox = frameIndex < irisBoundingBoxes.count ? irisBoundingBoxes[frameIndex] : .zero
        }

        let imageWidth = imageSize.width
        let imageHeight = imageSize.height

        let xCenter = boundingBox.origin.x + boundingBox.width / 2
        let yCenter = boundingBox.origin.y + boundingBox.height / 2

        let radius: CGFloat = frameIndex < radii.count ? CGFloat(radii[frameIndex]) : (boundingBox.width / 2)
        let strokeWidth: CGFloat = 3.5
        let strokeColor = UIColor.green.withAlphaComponent(1)

        UIGraphicsBeginImageContextWithOptions(CGSize(width: imageWidth, height: imageHeight), false, 1.0)
        guard let context = UIGraphicsGetCurrentContext() else { return finalImage }
        context.clear(CGRect(x: 0, y: 0, width: imageWidth, height: imageHeight))
        context.setStrokeColor(strokeColor.cgColor)
        context.setLineWidth(strokeWidth)
        
        let circleRect = CGRect(x: xCenter - radius, y: yCenter - radius, width: radius * 2, height: radius * 2)
        context.strokeEllipse(in: circleRect)

        let overlayUIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        if let overlayUIImage = overlayUIImage, let overlayCIImage = CIImage(image: overlayUIImage) {
            finalImage = overlayCIImage.composited(over: finalImage)
        }

        return finalImage
    }
    
    static func moveMediaToDocumentsDirectory(_ tempURL: URL, desiredFileName: String = "video.mp4") -> URL? {
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
    
    // Creates the string content for the PLR metrics file.
    private static func createPLRMetricsContent(results: VideoTestResults.PLRResults, timestamp: String) -> String {
        var content = "PLR Metrics\n"
        content += "Timestamp: \(timestamp)\n"
        content += "Max Pupil Diameter: \(results.maxPD ?? 0.0)\n"
        content += "Min Pupil Diameter: \(results.minPD ?? 0.0)\n"
        content += "Latency: \(results.latency ?? "N/A")\n"
        content += "Max Constriction: \(results.maxConstriction ?? 0.0)\n"
        content += "75% Recovery: \(results.seventyFivePercentRecovery ?? "N/A")\n"
        content += "Average Dilation Velocity: \(results.adv ?? 0.0)\n"
        content += "Average Constriction Velocity: \(results.acv ?? 0.0)\n"
        return content
    }
    
    // Saves the PLR metrics to a timestamped text file in the app's Documents directory.
    static func savePLRMetrics(results: VideoTestResults.PLRResults) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())
        let fileName = "plr_metrics_\(timestamp).txt"
        
        let content = createPLRMetricsContent(results: results, timestamp: timestamp)
        
        guard let docFolder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                fatalError()
        }
        
        let fileURL = docFolder.appendingPathComponent(fileName)
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            print("PLR metrics saved to: \(fileURL.path)")
        }
        catch {
            fatalError(error.localizedDescription)
        }
    }
    
    static func saveVideo(url: URL) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        }) { success, error in
            if let error = error {
                print("Error saving video: \(error.localizedDescription)")
            } else if success {
                print("Video saved successfully!")
            }
        }
    }
    
    static func saveGraph(url: URL) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: url)
        }) { success, error in
            if let error = error {
                print("Error saving graph: \(error.localizedDescription)")
            } else if success {
                print("Graph saved successfully!")
            }
        }
    }
    
    // MARK: - Post Processing
    static func processRecordedVideo(at url: URL,
                                     testType: String,
                                     imageSize: CGSize,
                                     irisBoundingBoxes: [CGRect],
                                     pupilBoundingBoxes: [CGRect],
                                     completion: @escaping (URL?, [Double]?) -> Void) {
        let asset = AVAsset(url: url)
        let cropFlag: Bool = testType == "VOMS"
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            completion(nil, nil)
            return
        }
        
        let outputURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mov
        exportSession.timeRange = CMTimeRange(start: .zero, duration: asset.duration)
        var frameIndex = 0
        
        let plotData: [Double] = (testType == "VOMS") ?
            RadiusDataProcessor.getProcessedIrisPos(from: irisBoundingBoxes) :
            RadiusDataProcessor.getProcessedPlrRadius(from: pupilBoundingBoxes)
        
        let composition = AVMutableVideoComposition(asset: asset) { request in
            let ciImage = request.sourceImage
            let processedImage: CIImage = cropFlag ?
                cropImage(on: ciImage.oriented(.right)) : ciImage
            let outputImage = overlayBoundingBox(
                on: processedImage,
                frameIndex: frameIndex,
                testType: testType,
                imageSize: imageSize,
                irisBoundingBoxes: irisBoundingBoxes,
                pupilBoundingBoxes: pupilBoundingBoxes,
                radii: testType == "VOMS" ? [] : plotData
            )
            frameIndex += 1
            request.finish(with: outputImage, context: nil)
        }
        
        if cropFlag {
            composition.renderSize = CGSize(width: 640, height: 640)
        }
        composition.frameDuration = CMTime(value: 1, timescale: 30)
        exportSession.videoComposition = composition
        
        exportSession.exportAsynchronously {
            DispatchQueue.main.async {
                if exportSession.status == .completed {
                    completion(outputURL, plotData)
                } else {
                    completion(nil, nil)
                }
            }
        }
    }
}
