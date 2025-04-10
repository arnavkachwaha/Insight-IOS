//
//  NewOutputView.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 4/1/25.
//

import SwiftUI

struct LocalOutputView: View {
    var testResults: VideoTestResults
    var testType: String
    var onRedo: () -> Void
    var onProceed: () -> Void
    
    init(testResults: VideoTestResults, testType: String, onRedo: @escaping () -> Void, onProceed: @escaping () -> Void) {
        self.testResults = testResults
        self.testType = testType
        self.onRedo = onRedo
        self.onProceed = onProceed
    }
    
    
    var body: some View {
        ZStack {
            Color(red: 250/255, green: 250/255, blue: 250/255)
            ScrollView {
                VStack {
                    Spacer()
                    HeaderView()
                    Spacer()
                
                    if self.testType == "PLR"{
                        VideoPlayerView(videoUrl: self.testResults.plrResults?.processedVideoURL)
                        PlrGraphView(radii: self.testResults.plrResults?.plotData ?? [], fps: self.testResults.plrResults?.fps ?? 30)
                        
                        Text("PLR METRICS").font(.title3).fontWeight(.bold).padding(.top, 10)
                        Text("""
                        maxPD: \(String(format: "%.3f", self.testResults.plrResults?.maxPD ?? 0))
                        minPD: \(String(format: "%.3f", self.testResults.plrResults?.minPD ?? 0))
                        max Constriction: \(String(format: "%.3f", self.testResults.plrResults?.maxConstriction ?? 0))
                        75% Recovery Time: \(self.testResults.plrResults?.seventyFivePercentRecovery ?? "0")
                        latency: \(self.testResults.plrResults?.latency ?? "0")
                        adv: \(String(format: "%.3f", self.testResults.plrResults?.adv ?? 0))
                        acv: \(String(format: "%.3f", self.testResults.plrResults?.acv ?? 0))
                        """)
                        .multilineTextAlignment(.leading)
                        .font(.subheadline)
                        .padding(.all, 10)
                        
                    } else {
                        VideoPlayerView(videoUrl: self.testResults.vomsResults?.processedVideoURL)
                        VomsGraphView(plotData: self.testResults.vomsResults?.plotData ?? [], fps: self.testResults.vomsResults?.fps ?? 30)
                    }
                    HStack {
                        Button(action: { onRedo() }) {
                            Text("Redo")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(20)
                        }
                        .padding(.leading, 40)
                        .padding(.top, 5)
                        .padding(.bottom, 10)
                        Spacer()
                        Button(action: { onProceed() }) {
                            Text("Proceed")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(20)
                        }
                        .padding(.trailing, 40)
                        .padding(.top, 5)
                        .padding(.bottom, 10)
                    }
                }
            }
            .padding(.all, 30)
        }
    }
}

#Preview {
    LocalOutputView(
        testResults: VideoTestResults(),
        testType: "PLR",
        onRedo: { print("Redo pressed") },
        onProceed: { print("Proceed pressed") }
    )
}

