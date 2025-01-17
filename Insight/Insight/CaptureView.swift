//
//  CaptureView.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 10/11/24.
//

import SwiftUI

struct CaptureView: View {
    @ObservedObject var viewModel: ContentViewModel
    @State private var shouldStartTrackerAnimation = false
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
                            } else if viewModel.currentView == "VOMS" {
                                TrackerView(shouldAnimate: $shouldStartTrackerAnimation)
                            }
                        }
                    )
                VStack {
                    Spacer()
                    FooterView(frameHandler: viewModel.frameHandler,onRecordingStateChanged: { isRecording in
                        shouldStartTrackerAnimation = isRecording
                    })
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
                            viewModel.switchViews(view: "SCAT6")
                        default:
                            break
                        }
                    }
                )
                
            case .loading:
                LoadingView()
            }
            HeaderView()
        }.alert(isPresented: $viewModel.showAlert) {
            Alert(
                title: Text("Error"),
                message: Text(viewModel.alertMessage),
                dismissButton: .default(Text("OK"), action: {
                    viewModel.restartSession()
                })
            )
        }
    }
}

#Preview {
    CaptureView(viewModel: ContentViewModel(frameHandler: FrameHandler()))
}
