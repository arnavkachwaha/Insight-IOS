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
    @State private var showFooter = true  // Control Footer visibility
    
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
                
                // Display FooterView only if `showFooter` is true
                if showFooter {
                    VStack {
                        FooterView(frameHandler: viewModel.frameHandler, onRecordingStateChanged: { isRecording in
                            shouldStartTrackerAnimation = isRecording
                            
                            if isRecording {
                                // Hide the FooterView after 5ms
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.005) {
                                    showFooter = false
                                }
                            }
                        })
                    }
                }
                
//            case .playback(let videoURL):
//                PlaybackView(
//                    videoUrl: videoURL,
//                    onRedo: {
//                        viewModel.restartSession()
//                        self.shouldStartTrackerAnimation = false
//                        showFooter = true  // Show Footer again on redo
//                    },
//                    onUse: {
//                        viewModel.uploadDataToServer()
//                    }
//                )
                
            case .localOutput(let testResults, let testType):
                LocalOutputView(
                    testResults: testResults,
                    testType: testType,
                    onRedo: {
                        viewModel.restartSession()
                        self.shouldStartTrackerAnimation = false
                        showFooter = true
                    },
                    onProceed: {
                        navigationPath.removeLast(navigationPath.count)
                        self.shouldStartTrackerAnimation = false
                        viewModel.uploadDataToServer(view: viewModel.currentView)
                    }
                )
                
            case .loading:
                LoadingView()
//            case .output(videoURL: _, graphURL: _):
//                LoadingView()
            }
        
        }
        .ignoresSafeArea()
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
          if showFooter {
            ToolbarItem(placement: .navigationBarLeading) {
                CustomBackButton(label: "")
            }
          }
        }
        .alert(isPresented: $viewModel.showAlert) {
            Alert(
                title: Text("Error"),
                message: Text(viewModel.alertMessage),
                dismissButton: .default(Text("OK"), action: {
                    viewModel.restartSession()
                    showFooter = true  // Reset footer visibility on restart
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
