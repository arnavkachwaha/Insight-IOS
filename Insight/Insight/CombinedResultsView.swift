//
//  CombinedResultsView.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 1/30/25.
//

import SwiftUI

struct CombinedResultsView: View {
    @ObservedObject var videoResults: VideoTestResults
    @ObservedObject var scat6Results: NeuroScreenResults
    @Binding var navigationPath: NavigationPath

    var body: some View {
        ZStack {
            Color(red: 240/255, green: 240/255, blue: 240/255).edgesIgnoringSafeArea(.all)
            ZStack {
                ScrollView {
                    HeaderView()
                    VStack() {
                        Text("Combined Results")
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.all, 10)
                        
                        // PLR Section
                        if let plrResults = videoResults.plrResults {
                            Section(header: Text("PLR Results")
                                .font(.title)
                                .fontWeight(.bold)
                                .padding(.all, 15)) {
                                    VideoResultView(videoUrl: plrResults.videoURL, graphUrl: plrResults.graphURL)
                                }
                        }
                        
                        // VOMS Section
                        if let vomsResults = videoResults.vomsResults {
                            Section(header: Text("VOMS Results")
                                .font(.title)
                                .fontWeight(.bold)
                                .padding(.all, 15)) {
                                    VideoResultView(videoUrl: vomsResults.videoURL, graphUrl: vomsResults.graphURL)
                                }
                        }
                        
                        // SCAT6 Section
                        Section(header: Text("SCAT6 Results")
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.all, 15)) {
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
                            }
                    }
                    .padding(.all, 1)
                }
            }
        }
    }
}

struct VideoResultView: View {
    var videoUrl: URL?
    var graphUrl: URL?

    var body: some View {
        VStack {
            VideoPlayer(videoURL: self.videoUrl!)
                .frame(width: 430, height: 320)
                .padding(.bottom, 0.5)
            
            AsyncImage(url: graphUrl) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 430, height: 320)
                    
                } else {
                    Color.red
                        .frame(width: 435, height: 320)
                }
            }
        }
    }
}


#Preview {
    @Previewable @State var navigationPath = NavigationPath()
    @Previewable @State var videoTestResults = VideoTestResults()
    @Previewable @State var scat6Results = NeuroScreenResults()
    CombinedResultsView(videoResults: videoTestResults, scat6Results: scat6Results, navigationPath: $navigationPath)
}
