//
//  CaptureView.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 10/11/24.
//

import SwiftUI

struct CaptureView: View {
    @ObservedObject var viewModel: ContentViewModel
    @Binding var navigationPath: NavigationPath
    @State private var shouldStartTrackerAnimation = false
    
    var body: some View {
        ZStack {
            Color(.black).edgesIgnoringSafeArea(.all)
            
            switch viewModel.captureState {
            case .recording:
                CameraView(frameHandler: viewModel.frameHandler)
                    .cornerRadius(25)
                    .overlay(
                        Group {
                            if viewModel.currentView == "PLR" {
                                EyeMask(yOffset: 200)
                            } else if viewModel.currentView == "VOMS" {
                                TrackerView(
                                    shouldAnimate: $shouldStartTrackerAnimation,
                                    onAnimationEnd: {
                                        viewModel.stopRecording()
                                    }
                                )
                            }
                        }
                    )
                VStack {
                    HeaderView()
                    Spacer()
                    FooterView(frameHandler: viewModel.frameHandler, onRecordingStateChanged: { isRecording in
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
                        navigationPath.removeLast(navigationPath.count)
                    }
                )
                
            case .loading:
                LoadingView()
            }
        
        }
        .alert(isPresented: $viewModel.showAlert) {
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
    @Previewable @State var navigationPath = NavigationPath()
    @Previewable @State var testResults = VideoTestResults()
    return CaptureView(viewModel: ContentViewModel(frameHandler: FrameHandler(), currentView: "PLR", testResults: testResults), navigationPath: $navigationPath)
}
