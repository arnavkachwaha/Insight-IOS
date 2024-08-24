import CoreML
import UIKit

class CyclopsProcessor {
    private var model: cyclops_782_1x?

    init() {
        loadModel()
    }

    private func loadModel() {
        // Initialize the model
        guard let modelURL = Bundle.main.url(forResource: "cyclops_782_1x", withExtension: "mlmodelc") else {
            fatalError("Failed to find model URL.")
        }
        do {
            self.model = try cyclops_782_1x(contentsOf: modelURL)
        } catch {
            fatalError("Failed to load the model: \(error)")
        }
    }

    func runModel(on image: UIImage) -> (originalImage: UIImage, maskImage: UIImage?) {
        guard let model = self.model else {
            print("Model is not loaded.")
            return (originalImage: image, maskImage: nil)
        }
        
        // Convert the UIImage to a normalized MLMultiArray
        guard let mlMultiArray = image.toNormalizedMLMultiArray() else {
            print("Failed to convert the image to a normalized MLMultiArray.")
            return (originalImage: image, maskImage: nil)
        }

        // Create the model input
        let input = cyclops_782_1xInput(pixel_values: mlMultiArray)

        // Make the prediction
        do {
            let output = try model.prediction(input: input)

            // Extract the mask from the output (assuming similar to 'var_1199' in Python)
            if let maskArray = output.featureValue(for: "var_1199")?.multiArrayValue {
                // Process the output mask (resize, interpret, etc.)
                if let processedMask = postProcessMask(maskArray) {
                    // Return both the original and processed mask images
                    return (originalImage: image, maskImage: processedMask)
                }
            }
        } catch {
            print("Failed to make a prediction: \(error)")
        }

        return (originalImage: image, maskImage: nil)
    }

    private func postProcessMask(_ maskArray: MLMultiArray) -> UIImage? {
        // Assuming maskArray is of shape [1, height, width] or [1, channels, height, width]
        let numChannels = maskArray.shape[1].intValue
        let maskHeight = maskArray.shape[2].intValue
        let maskWidth = maskArray.shape[3].intValue

        // Convert MLMultiArray to a float buffer pointer
        let maskDataPointer = UnsafeMutablePointer<Float>(OpaquePointer(maskArray.dataPointer))
        let maskData = UnsafeBufferPointer(start: maskDataPointer, count: numChannels * maskHeight * maskWidth)

        // Prepare data for the final mask with transparency (0) and white (255) mask
        var finalMask = [UInt8](repeating: 0, count: maskHeight * maskWidth * 4)

        for y in 0..<maskHeight {
            for x in 0..<maskWidth {
                var maxProb: Float = -Float.greatestFiniteMagnitude
                var bestClass = 0

                for c in 0..<numChannels {
                    let index = c * maskHeight * maskWidth + y * maskWidth + x
                    let value = maskData[index]

                    if value > maxProb {
                        maxProb = value
                        bestClass = c
                    }
                }

                let pixelIndex = (y * maskWidth + x) * 4

                if bestClass == 1 {
                    // Set to white and opaque
                    finalMask[pixelIndex] = 255      // R
                    finalMask[pixelIndex + 1] = 255  // G
                    finalMask[pixelIndex + 2] = 255  // B
                    finalMask[pixelIndex + 3] = 255  // A (opaque)
                } else {
                    // Set to transparent
                    finalMask[pixelIndex] = 0        // R
                    finalMask[pixelIndex + 1] = 0    // G
                    finalMask[pixelIndex + 2] = 0    // B
                    finalMask[pixelIndex + 3] = 0    // A (transparent)
                }
            }
        }

        // Create CGImage from the data
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: &finalMask,
                                      width: maskWidth,
                                      height: maskHeight,
                                      bitsPerComponent: 8,
                                      bytesPerRow: maskWidth * 4,
                                      space: colorSpace,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue),
              let cgImage = context.makeImage() else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }


}

// UIImage extension to handle the conversion to MLMultiArray
extension UIImage {
    func toNormalizedMLMultiArray(inputShape: (Int, Int, Int, Int) = (1, 3, 480, 640)) -> MLMultiArray? {
        guard let cgImage = self.cgImage else { return nil }

        let width = inputShape.3 // 640
        let height = inputShape.2 // 480
        let batchSize = inputShape.0 // 1
        let channels = inputShape.1 // 3

        // Resize image to match input shape
        UIGraphicsBeginImageContext(CGSize(width: width, height: height))
        self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        guard let resizedCGImage = resizedImage?.cgImage else { return nil }

        // Define mean and standard deviation for normalization
        let mean: [Float] = [0.6019, 0.4767, 0.4340]
        let std: [Float] = [0.229, 0.224, 0.225]

        // Create MLMultiArray
        guard let mlMultiArray = try? MLMultiArray(shape: [NSNumber(value: batchSize), NSNumber(value: channels), NSNumber(value: height), NSNumber(value: width)], dataType: .float32) else {
            return nil
        }

        // Convert the CGImage to CVPixelBuffer
        guard let pixelBuffer = CVPixelBuffer.create(from: resizedCGImage) else { return nil }

        // Lock the pixel buffer base address
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags.readOnly)
        defer {
            CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags.readOnly)
        }

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            return nil
        }

        let buffer = baseAddress.assumingMemoryBound(to: UInt8.self)

        // Normalize pixel values and populate MLMultiArray
        for y in 0..<height {
            for x in 0..<width {
                let pixelIndex = (y * width + x) * 4
                let r = Float(buffer[pixelIndex + 2]) / 255.0
                let g = Float(buffer[pixelIndex + 1]) / 255.0
                let b = Float(buffer[pixelIndex]) / 255.0

                let normalizedR = (r - mean[0]) / std[0]
                let normalizedG = (g - mean[1]) / std[1]
                let normalizedB = (b - mean[2]) / std[2]

                mlMultiArray[[0, 0, NSNumber(value: y), NSNumber(value: x)]] = NSNumber(value: normalizedR)
                mlMultiArray[[0, 1, NSNumber(value: y), NSNumber(value: x)]] = NSNumber(value: normalizedG)
                mlMultiArray[[0, 2, NSNumber(value: y), NSNumber(value: x)]] = NSNumber(value: normalizedB)
            }
        }

        return mlMultiArray
    }
}

// Helper function to create a CVPixelBuffer from a CGImage
extension CVPixelBuffer {
    static func create(from cgImage: CGImage) -> CVPixelBuffer? {
        let width = cgImage.width
        let height = cgImage.height
        let attributes: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]

        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            attributes as CFDictionary,
            &pixelBuffer
        )

        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }

        CVPixelBufferLockBaseAddress(buffer, [])

        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
        ) else {
            CVPixelBufferUnlockBaseAddress(buffer, [])
            return nil
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        CVPixelBufferUnlockBaseAddress(buffer, [])

        return buffer
    }
}
