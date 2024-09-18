//
//  ContentView.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 6/25/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel(frameHandler: FrameHandler())

    var body: some View {
        VStack {
            bodyContent(viewModel.isRecording)
        }
    }

    @ViewBuilder
    private func bodyContent(_ isRecording: Bool) -> some View {
        ZStack {
            if isRecording {
                CameraView(frameHandler: viewModel.frameHandler)
                    .overlay(EyeMask(yOffset: 200))
                VStack {
                    Spacer()
                    FooterView(frameHandler: viewModel.frameHandler)
                }
            } else if let videoURL = viewModel.videoURL {
                PlaybackView(videoURL: videoURL, onRedo: {
                    viewModel.restartSession()  
                }, onUse: {
                    // Action for Use (navigate to another view later)
                })
            } else {
                Text("No video available")
            }
        }
    }
}


#Preview {
    ContentView()
}
