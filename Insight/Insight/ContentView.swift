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
            ZStack {
                if viewModel.isRecording && viewModel.isFetchingVideo == false {
                    CameraView(frameHandler: viewModel.frameHandler)
                        .cornerRadius(25)
                        .overlay(EyeMask(yOffset: 200))
                    VStack {
                        Spacer()
                        FooterView(frameHandler: viewModel.frameHandler)
                    }
                    
                } else if viewModel.isRecording == false && viewModel.isFetchingVideo == false && viewModel.isVideoFetched == false {
                    PlaybackView(
                        videoUrl: viewModel.recordedVideoURL,
                        onRedo: {
                            viewModel.restartSession()
                        },
                        onUse:{
                            viewModel.uploadAndFetchVideo()
                        }
                    )
                    
                } else if viewModel.isVideoFetched == true && viewModel.isFetchingVideo == false {
                    PlaybackView(
                        videoUrl: viewModel.fetchedVideoURL,
                        onRedo: {
                            viewModel.restartSession()
                        },
                        onUse:{
                            print("On Use Pressed")
                        }
                    )
                    
                } else {
                    LoadingView()
                }
                HeaderView()
            }

        }
    }
}

#Preview {
    ContentView()
}
