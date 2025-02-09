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
        var graphURL: URL?
    }
    
    struct VOMSResults {
        var videoURL: URL?
        var graphURL: URL?
    }
    
    func reset() {
        plrResults = nil
        vomsResults = nil
    }
}
