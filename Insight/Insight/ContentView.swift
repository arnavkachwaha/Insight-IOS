//
//  ContentView.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 6/25/24.
//

//
//  ContentView.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 6/25/24.
//

import SwiftUI

struct ContentView: View {
    @State private var navigationPath = NavigationPath()
    @State private var viewModel: ContentViewModel? = nil
    @StateObject private var scat6Results = NeuroScreenResults()
    @StateObject private var videoResults = VideoTestResults()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            TestMenuView(navigationPath: $navigationPath, VideoResults: videoResults, Scat6Results: scat6Results )
                .navigationDestination(for: String.self) { test in
                    switch test {
                    case "PLR":
                        let viewModel = ContentViewModel(frameHandler: FrameHandler(), currentView: "PLR", testResults: videoResults)
                        CaptureView(viewModel: viewModel, navigationPath: $navigationPath)
                            .navigationBarTitleDisplayMode(.inline)
//                            .withCustomBackButton()
                            .onDisappear {
                                self.viewModel = nil
                            }
                    case "VOMS":
                        let viewModel = ContentViewModel(frameHandler: FrameHandler(), currentView: "VOMS", testResults: videoResults)
                        CaptureView(viewModel: viewModel, navigationPath: $navigationPath)
                            .navigationBarTitleDisplayMode(.inline)
//                            .withCustomBackButton()
                            .onDisappear {
                                self.viewModel = nil
                            }
                    case "SCAT6":
                        ObservableSignsView(results: scat6Results, navigationPath: $navigationPath)
                            .navigationBarTitleDisplayMode(.inline)
                            .withCustomBackButton()
                    case "CombinedResults":
                        CombinedResultsView(navigationPath: $navigationPath, videoResults: videoResults, scat6Results: scat6Results)
                            .navigationBarTitleDisplayMode(.inline)
                            .withCustomBackButton()
                    default:
                        Text("Unknown View")
                    }
                }
        }
    }
}

#Preview {
    ContentView()
}
