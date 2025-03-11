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
    
    @State private var detectedBox: CGRect? = nil
    @State private var shouldStartTrackerAnimation = false
    
    var body: some View {
        ZStack {
            Color(.black).edgesIgnoringSafeArea(.all)
            
            switch viewModel.captureState {
            case .recording:
                CameraView(frameHandler: viewModel.frameHandler, detectedBox: $detectedBox)
                    .cornerRadius(25)
                    .overlay(
                        Group {
                            if viewModel.currentView == "PLR" {
                                EyeCutoutView(yOffset: 250, detectedBox: detectedBox)
                            } else if viewModel.currentView == "VOMS" {
                                TrackerView_1(
                                    shouldAnimate: $shouldStartTrackerAnimation,
                                    onAnimationEnd: {
                                        viewModel.stopRecording()
                                    }
                                )
                            }
                        }
                    )
                VStack {
                    FooterView(frameHandler: viewModel.frameHandler, onRecordingStateChanged: { isRecording in
                        shouldStartTrackerAnimation = isRecording
                    })
                }
                
            case .playback(let videoURL):
                PlaybackView(
                    videoUrl: videoURL,
                    onRedo: {
                        viewModel.restartSession()
                        self.shouldStartTrackerAnimation = false
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
                        self.shouldStartTrackerAnimation = false
                    },
                    onProceed: {
                        navigationPath.removeLast(navigationPath.count)
                        self.shouldStartTrackerAnimation = false
                    }
                )
                
            case .loading:
                LoadingView()
            }
        
        }
        .ignoresSafeArea()
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
