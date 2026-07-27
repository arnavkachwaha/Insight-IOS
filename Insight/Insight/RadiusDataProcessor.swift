//
//  RadiusDataProcessor.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 4/1/25.
//

import Foundation
import CoreGraphics
import SwiftUI

public struct RadiusDataProcessor {
    
    /// Computes radii from an array of bounding boxes using the formula: (width + height) / 4.
    static func computeRadii(from boundingBoxes: [CGRect]) -> [Double] {
        return boundingBoxes.map { Double(($0.width) / 2.0) }
    }
    
    /// Removes outliers from the data using z-score filtering.
    public static func removeOutliers(_ data: [Double], threshold: Double = 2.0) -> [Double] {
        guard !data.isEmpty else { return data }
        let mean = data.reduce(0, +) / Double(data.count)
        
        // Prevent division by zero if all values happen to be identical
        let variance = data.map { pow($0 - mean, 2) }.reduce(0, +) / Double(data.count)
        let std = variance > 0 ? sqrt(variance) : 1.0
        
        var cleaned = data
        for i in 0..<cleaned.count {
            if abs(cleaned[i] - mean) / std >= threshold {
                // CRUCIAL: Replace the outlier instead of deleting it.
                // If it's the first frame, use the mean. Otherwise, hold the previous valid frame.
                cleaned[i] = (i > 0) ? cleaned[i-1] : mean
            }
        }
        
        return cleaned
    }
    
    /// Applies a first-order exponential low-pass filter to the data.
    static func applyLowpassFilter(_ data: [Double], cutoff: Double, fs: Double) -> [Double] {
        guard !data.isEmpty else { return data }
        let dt = 1.0 / fs
        let RC = 1.0 / (2 * Double.pi * cutoff)
        let alpha = dt / (RC + dt)
        
        var filtered = [Double](repeating: data[0], count: data.count)
        for i in 1..<data.count {
            filtered[i] = alpha * data[i] + (1 - alpha) * filtered[i - 1]
        }
        return filtered
    }
    
    /// Performs natural cubic spline smoothing (interpolation) on the given data.
    static func cubicSplineSmoothing(timeValues: [Double], data: [Double], denseCount: Int = 1000) -> ([Double], [Double]) {
        let n = timeValues.count
        guard n > 1 else { return (timeValues, data) }
        
        // Compute h[i] = timeValues[i+1] - timeValues[i]
        var h = [Double](repeating: 0.0, count: n-1)
        for i in 0..<n-1 {
            h[i] = timeValues[i+1] - timeValues[i]
        }
        
        // Set up the system for second derivatives.
        var alpha = [Double](repeating: 0.0, count: n)
        for i in 1..<n-1 {
            alpha[i] = (3/h[i]) * (data[i+1] - data[i]) - (3/h[i-1]) * (data[i] - data[i-1])
        }
        
        var l = [Double](repeating: 0.0, count: n)
        var mu = [Double](repeating: 0.0, count: n)
        var z = [Double](repeating: 0.0, count: n)
        
        l[0] = 1.0
        mu[0] = 0.0
        z[0] = 0.0
        
        for i in 1..<n-1 {
            l[i] = 2 * (timeValues[i+1] - timeValues[i-1]) - h[i-1] * mu[i-1]
            mu[i] = h[i] / l[i]
            z[i] = (alpha[i] - h[i-1] * z[i-1]) / l[i]
        }
        l[n-1] = 1.0
        z[n-1] = 0.0
        
        // Compute second derivatives m (natural spline: m[0] = m[n-1] = 0)
        var m = [Double](repeating: 0.0, count: n)
        m[n-1] = 0.0
        for j in stride(from: n-2, through: 0, by: -1) {
            m[j] = z[j] - mu[j] * m[j+1]
        }
        
        // Build a dense time grid and evaluate the spline.
        let tMin = timeValues.first!
        let tMax = timeValues.last!
        let dtDense = (tMax - tMin) / Double(denseCount - 1)
        var denseTime = [Double]()
        var denseSpline = [Double]()
        
        for i in 0..<denseCount {
            let t = tMin + Double(i) * dtDense
            // Find the interval [timeValues[j], timeValues[j+1]] that contains t.
            var j = 0
            for k in 0..<n-1 {
                if t >= timeValues[k] && t <= timeValues[k+1] {
                    j = k
                    break
                }
            }
            let hj = timeValues[j+1] - timeValues[j]
            let A = (timeValues[j+1] - t) / hj
            let B = (t - timeValues[j]) / hj
            let splineValue = A * data[j] + B * data[j+1] +
                ((A*A*A - A) * m[j] + (B*B*B - B) * m[j+1]) * (hj * hj) / 6.0
            denseTime.append(t)
            denseSpline.append(splineValue)
        }
        
        return (denseTime, denseSpline)
    }
    
    /// Computes a centered moving average that preserves the array length
        static func movingAverage(data: [Double], windowSize: Int) -> [Double] {
            guard data.count >= windowSize else { return data }
            var result = [Double]()
            let halfWindow = windowSize / 2
            
            for i in 0..<data.count {
                // Prevent out-of-bounds indexing at the edges
                let start = max(0, i - halfWindow)
                let end = min(data.count - 1, i + halfWindow)
                
                let window = data[start...end]
                let avg = window.reduce(0, +) / Double(window.count)
                result.append(avg)
            }
            return result
        }
    
    public static func getPlrMetrics(frameRadius: [Double], fps: Double = 30.0, mmPerPixel: Double) -> (maxPD: Double, minPD: Double, latency: String, maxConstriction: Double, seventyFivePercentRecovery: String, adv: Double, acv: Double) {
            let flashPoint = 15
            
            guard frameRadius.count > flashPoint else { return (0, 0, "0 ms", 0, "0 s", 0, 0) }
            
            // 1. Find Baseline (Stable average just before flash)
            let baselineSegment = Array(frameRadius[max(0, flashPoint - 15)..<flashPoint])
            let baselineRadiusPx = baselineSegment.reduce(0, +) / Double(baselineSegment.count)
            let maxPD = baselineRadiusPx * 2.0 * mmPerPixel
            

            // 2. Find Peak Constriction (Min PD)
            let constrictionWindow = Array(frameRadius[flashPoint...])
            let minRadiusPx = constrictionWindow.min() ?? 0.0
            let minPD = minRadiusPx * 2.0 * mmPerPixel
            
            // Absolute index in the main array
            let minPDIndex = flashPoint + (constrictionWindow.firstIndex(of: minRadiusPx) ?? 0)
            
            // 3. Find Onset (Latency Point)
            // FIX A: Start searching EXACTLY at the flash point (remove the +6 frame blindfold)
            // FIX B: Use a strict 0.15 mm physical drop so large pupils aren't penalized
            let dropThresholdPx = baselineRadiusPx - (0.15 / (2.0 * mmPerPixel))
            let onsetIndex = frameRadius[flashPoint...].firstIndex { $0 <= dropThresholdPx } ?? flashPoint
            
            let latencyValue = round(Double(abs(onsetIndex - flashPoint)) / fps * 1000.0)
            let latency = "\(Int(latencyValue)) ms"
            
            // 4. Calculate ACV (Onset to Minimum)
            let maxConstriction = round((maxPD - minPD) * 100) / 100.0
            let constrictionFrames = max(1, minPDIndex - onsetIndex)
            let constrictionTime = Double(constrictionFrames) / fps
            let constrictionDistanceMm = (frameRadius[onsetIndex] - frameRadius[minPDIndex]) * 2.0 * mmPerPixel
            let acv: Double = round((constrictionDistanceMm / constrictionTime) * 100) / 100.0

            // 5. Calculate 75% Recovery Point
            let recoveryThresholdPx = minRadiusPx + ((baselineRadiusPx - minRadiusPx) * 0.75)
            
            // Search for the recovery point, default to the very last frame if not found
            let seventyFivePercentIndex = frameRadius[minPDIndex...].firstIndex { $0 >= recoveryThresholdPx } ?? (frameRadius.count - 1)
            let recoveryFrames = max(1, seventyFivePercentIndex - minPDIndex)
            
            // FIX: If the index hit the end of the video, flag it so it doesn't log a false time
            let seventyFivePercentRecovery: String
            if seventyFivePercentIndex == frameRadius.count - 1 {
                seventyFivePercentRecovery = "Incomplete"
            } else {
                let seventyFivePercentRecoveryValue = round((Double(recoveryFrames) / fps) * 100) / 100.0
                seventyFivePercentRecovery = "\(seventyFivePercentRecoveryValue) s"
            }
            
            // 6. Calculate ADV (Minimum to 75% Recovery or End of Video)
            let dilationTime = Double(recoveryFrames) / fps
            let dilationDistanceMm = (frameRadius[seventyFivePercentIndex] - frameRadius[minPDIndex]) * 2.0 * mmPerPixel
            
            // Added a safeguard to prevent dividing by zero if minPDIndex is exactly at the end
            let adv: Double = dilationTime != 0 ? round((dilationDistanceMm / dilationTime) * 100) / 100.0 : 0.0
            
            return (maxPD, minPD, latency, maxConstriction, seventyFivePercentRecovery, adv, acv)
        }

    
    public static func getProcessedPlrRadius(from boundingBoxes: [CGRect]) -> [Double] {
        let rawRadii = self.computeRadii(from: boundingBoxes)
        let cleanedRadii = self.removeOutliers(rawRadii)
        let filteredRadii = self.applyLowpassFilter(cleanedRadii, cutoff: 1, fs: 30.0)
        let processedRadii = self.movingAverage(data: filteredRadii, windowSize: 5)
        return processedRadii
    }
    
    public static func getProcessedIrisPos(from boundingBoxes: [CGRect]) -> [Double] {
        let rawIrisValues = boundingBoxes.map { Double($0.origin.x + ($0.width / 2.0)) }
        let cleanedIrisPos = removeOutliers(rawIrisValues)
        let filteredIrisPos = applyLowpassFilter(cleanedIrisPos, cutoff: 1, fs: 30.0)
        let processedIrisPos = movingAverage(data: filteredIrisPos, windowSize: 5)
        return processedIrisPos
    }

}
