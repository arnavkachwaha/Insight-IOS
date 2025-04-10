//
//  VideoTestResults.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 1/30/25.
//

import Foundation

class VideoTestResults: ObservableObject{
    var plrResults: PLRResults?
    var vomsResults: VOMSResults?
    
    struct PLRResults {
        var videoURL: URL?
        var processedVideoURL: URL?
        var graphURL: URL?
        var plotData: [Double]?
        var fps: Double?
        var maxPD: Double?
        var minPD: Double?
        var latency: String?
        var maxConstriction: Double?
        var seventyFivePercentRecovery: String?
        var adv: Double?
        var acv: Double?
        var irisData: [CGRect]?
        var pupilData: [CGRect]?
    }
    
    struct VOMSResults {
        var videoURL: URL?
        var processedVideoURL: URL?
        var graphURL: URL?
        var plotData: [Double]?
        var fps: Double?
        var irisData: [CGRect]?
        var pupilData: [CGRect]?
    }
    
    func reset() {
        plrResults = nil
        vomsResults = nil
    }
}
