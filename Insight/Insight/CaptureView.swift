//
//  CaptureView.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 10/11/24.
//

import SwiftUI

struct CaptureView: View {
    @ObservedObject var viewModel: ContentViewModel
        var body: some View {
            ZStack {
                switch viewModel.captureState {
                case .recording:
                    CameraView(frameHandler: viewModel.frameHandler)
                        .cornerRadius(25)
                        .overlay(
                            Group {
                                if viewModel.currentView == "PLR" {
                                    EyeMask(yOffset: 200)
                                }
                            }
                        )
                    VStack {
                        Spacer()
                        FooterView(frameHandler: viewModel.frameHandler)
                    }

                case .playback(let videoURL):
                    PlaybackView(
                        videoUrl: videoURL,
                        onRedo: {
                            viewModel.restartSession()
                        },
                        onUse: {
                            viewModel.uploadAndFetchVideo()
                        }
                    )

                case .output(let videoURL, let graphURL):
                    OutputView(
                        videoUrl: videoURL,
                        graphUrl: graphURL,
                        onRedo: {
                            viewModel.restartSession()
                        },
                        onProceed: {
                            switch viewModel.currentView {
                                case "PLR":
                                viewModel.switchViews(view: "VOMS")
                                case "VOMS":
                                    viewModel.currentView = "SCAT6"
                                default:
                                    break
                            }
                        }
                    )

                case .loading:
                    LoadingView()
                }
                HeaderView()
            }
        }
}

#Preview {
    CaptureView(viewModel: ContentViewModel(frameHandler: FrameHandler()))
}
