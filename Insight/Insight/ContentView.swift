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
    @StateObject private var viewModel = ContentViewModel(frameHandler: FrameHandler())

    var body: some View {
        VStack {
            bodyContent(viewModel.isRecording, viewModel.isFetchingVideo)
        }
    }

    @ViewBuilder
    private func bodyContent(_ isRecording: Bool, _ isFetchingVideo: Bool) -> some View {
        ZStack {
            if isRecording {
                CameraView(frameHandler: viewModel.frameHandler)
                    .cornerRadius(25)
                    .overlay(EyeMask(yOffset: 200))
                VStack {
                    Spacer()
                    FooterView(frameHandler: viewModel.frameHandler)
                }
                HeaderView()
            }
            else{
                PlaybackView(
                    viewModel: viewModel,
                    onRedo: {
                        viewModel.restartSession()
                    }
                )
            }
        }
    }
}

#Preview {
    ContentView()
}
