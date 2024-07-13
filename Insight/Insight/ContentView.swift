//
//  ContentView.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 6/25/24.
//


import SwiftUI

struct ContentView: View {
    @State private var currentView: ViewType = .content
    @ObservedObject var frameHandler = FrameHandler()

    var body: some View {
        VStack {
            HeaderView()
            Spacer()
            
            if currentView == .content {
                ZStack {
                    CameraView(frameHandler: frameHandler)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                FooterView(frameHandler: frameHandler)
            } else if currentView == .videoPreview {
                VideoPreviewView()
            }
            
            Spacer()
        }
    }
}

enum ViewType {
    case content
    case videoPreview
}

struct VideoPreviewView: View {
    var body: some View {
        Text("This is the Video Preview View")
    }
}

#Preview {
    ContentView()
}
