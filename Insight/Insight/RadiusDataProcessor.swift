//
//  RadiusDataProcessor.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 4/1/25.
//

import Foundation
import CoreGraphics
import SwiftUICore

public struct RadiusDataProcessor {
    
    /// Computes radii from an array of bounding boxes using the formula: (width + height) / 4.
    static func computeRadii(from boundingBoxes: [CGRect]) -> [Double] {
        return boundingBoxes.map { Double(($0.width) / 2.0) }
    }
    
    /// Removes outliers from the data using z-score filtering.
    public static func removeOutliers(_ data: [Double], threshold: Double = 2.0) -> [Double] {
        guard !data.isEmpty else { return data }
        let mean = data.reduce(0, +) / Double(data.count)
        let std = sqrt(data.map { pow($0 - mean, 2) }.reduce(0, +) / Double(data.count))
        return data.filter { abs($0 - mean) / std < threshold }
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
    
    /// Computes a moving average for the given data.
    static func movingAverage(data: [Double], windowSize: Int) -> [Double] {
        guard data.count >= windowSize else { return data }
        var result = [Double]()
        for i in 0...(data.count - windowSize) {
            let window = data[i..<(i + windowSize)]
            let avg = window.reduce(0, +) / Double(windowSize)
            result.append(avg)
        }
        return result
    }
    
    public static func getPlrMetrics(frameRadius: [Double], fps: Double = 30.0) -> (maxPD: Double, minPD: Double, latency: String, maxConstriction: Double, seventyFivePercentRecovery: String, adv: Double, acv: Double) {
        let flashPoint = 40
        guard frameRadius.count > flashPoint else { return (0, 0, "0", 0, "0", 0, 0) }
        
        let firstSegment = Array(frameRadius[0..<flashPoint])
        let maxPD = firstSegment.max() ?? 0.0
        let secondSegment = Array(frameRadius[flashPoint..<frameRadius.count])
        let minPD = secondSegment.min() ?? 0.0
        let maxPDIndex = frameRadius.firstIndex(of: maxPD) ?? 0
        let minPDIndex = frameRadius.firstIndex(of: minPD) ?? 0
        
        // Latency: first index (after maxPDIndex) where value falls to <=95% of maxPD.
        let indexAfterMax = frameRadius[maxPDIndex...].firstIndex { $0 <= maxPD * 0.95 } ?? maxPDIndex
        let latencyValue = round(Double(abs(maxPDIndex - indexAfterMax)) / fps * 10000) / 10000.0
        let latency = "\(latencyValue)msec"
        
        // Maximum constriction: difference between maxPD and minPD (rounded to 2 decimals).
        let maxConstriction = round((maxPD - minPD) * 100) / 100.0
        let maxConstrictionTime = Double(abs(maxPDIndex - minPDIndex)) / fps
        let acv: Double = maxConstrictionTime != 0 ? round((maxConstriction / maxConstrictionTime) * 100) / 100.0 : 0.0

        // 75% Recovery: first index (after minPDIndex) where value >=75% of maxPD.
        let seventyFivePercentIndex = frameRadius[minPDIndex...].firstIndex { $0 >= maxPD * 0.75 } ?? minPDIndex
        let seventyFivePercentRecoveryValue = round(Double(seventyFivePercentIndex) / fps * 100) / 100.0
        let seventyFivePercentRecovery = "\(seventyFivePercentRecoveryValue)msec"
        
        // Dilation velocity (adv): from minPDIndex onward, the maximum dilated value.
        let subArray = Array(frameRadius[minPDIndex..<frameRadius.count])
        let maxDilatedDiameter = subArray.max() ?? minPD
        let maxDilatedDiameterIndex = minPDIndex + (subArray.firstIndex(of: maxDilatedDiameter) ?? 0)
        let maxDilationTime = Double(abs(maxDilatedDiameterIndex - minPDIndex)) / fps
        let adv: Double = maxConstrictionTime != 0 ? round((maxDilatedDiameter / maxConstrictionTime) * 100) / 100.0 : 0.0
        
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
