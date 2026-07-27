//
//  CombinedResultsView.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 1/30/25.
//

import SwiftUI

struct CombinedResultsView: View {
    @Binding var navigationPath: NavigationPath
    @ObservedObject var videoResults: VideoTestResults
    @ObservedObject var scat6Results: NeuroScreenResults
    
    var body: some View {
        ZStack {
            Color(red: 250/255, green: 250/255, blue: 250/255).edgesIgnoringSafeArea(.all)
            
            ZStack {
                ScrollView {
                    VStack() {
                        Text("Combined Results")
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.all, 10)
                        
                        Divider()
                            .background(Color.black.opacity(1))
                            .padding(.top, 10)
                        
                        // PLR Section
                        VStack {
                            Text("PLR")
                                .font(.title2)
                                .fontWeight(.bold)
                            VideoPlayerView(videoUrl: videoResults.plrResult?.processedVideoURL)
                            PlrGraphView(radii: videoResults.plrResult?.plotData ?? [], fps: videoResults.plrResult?.fps ?? 30)
                            
                            Text("PLR METRICS").font(.title3).fontWeight(.bold).padding(.top, 10)
                            Text("""
                            maxPD: \(String(format: "%.2f mm", videoResults.plrResult?.maxPD ?? 0))
                            minPD: \(String(format: "%.2f mm", videoResults.plrResult?.minPD ?? 0))
                            max Constriction: \(String(format: "%.2f mm", videoResults.plrResult?.maxConstriction ?? 0))
                            75% Recovery Time: \(videoResults.plrResult?.seventyFivePercentRecovery ?? "0 s")
                            latency: \(videoResults.plrResult?.latency ?? "0")
                            adv: \(String(format: "%.2f mm/s", videoResults.plrResult?.adv ?? 0))
                            acv: \(String(format: "%.2f mm/s", videoResults.plrResult?.acv ?? 0))
                            """)
                            .multilineTextAlignment(.leading)
                            .font(.subheadline)
                            .padding(.all, 10)


                        }.padding(.all, 10)
                        
                        Divider()
                            .background(Color.black.opacity(1))
                            .padding(.top, 10)
                        
                        // VOMS Section
                        VStack {
                            Text("VOMS")
                                .font(.title2)
                                .fontWeight(.bold)
                            VideoPlayerView(videoUrl: videoResults.vomsResult?.processedVideoURL)
                            VomsGraphView(plotData: videoResults.vomsResult?.plotData ?? [], fps: videoResults.vomsResult?.fps ?? 30)
                        }.padding(.all, 10)
                        
                        Divider()
                            .background(Color.black.opacity(1))
                            .padding(.top, 10)
                        
                        
                        // SCAT6 Section
                        VStack {
                            Text("SCAT6")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            SectionContainer {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Summary")
                                        .font(.system(size: 35, weight: .bold, design: .serif))
                                        .padding(.bottom, 10)
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text("Observable Signs: \(scat6Results.observableSignsCount)")
                                        Text("Cervical Spine Signs: \(scat6Results.cervicalSpineSignsCount)")
                                        Text("Ocular/Motor Signs: \(scat6Results.ocularMotorSignsCount)")
                                        Text("Glasgow Coma Score: \(scat6Results.glasgowComaScore)")
                                        Text("Maddocks Score: \(scat6Results.maddocksScore)/5")
                                    }
                                    .font(.system(size: 28, weight: .medium, design: .serif))
                                    .multilineTextAlignment(.leading)
                                    
                                }
                            }
                        }.padding(.all, 10)

                        Divider()
                            .background(Color.black.opacity(1))
                            .padding(.all, 10)
                        
                        HStack {
                            Spacer()
                            Button(action:{
                                navigationPath.removeLast(navigationPath.count)
                            }){
                                Text("Proceed")
                                    .font(.system(size: 20, weight: .bold, design: .serif))
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(width: 150, height: 50)
                                    .background(Color.blue)
                                    .cornerRadius(10)
                            }
                            .buttonStyle(PlainButtonStyle())
                            Spacer()
                        }.padding(.all, 10)
                    }
                }
                .padding(.all, 1)
            }
        }
    }
}

#Preview {
    @Previewable @State var navigationPath = NavigationPath()
    @Previewable @State var videoTestResults = VideoTestResults()
    @Previewable @State var scat6Results = NeuroScreenResults()
    CombinedResultsView(navigationPath: $navigationPath, videoResults: videoTestResults, scat6Results: scat6Results)
}
