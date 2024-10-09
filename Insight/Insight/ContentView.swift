//
//  ContentView.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 6/25/24.
//


import SwiftUI

struct ContentView: View {
    @ObservedObject var frameHandler = FrameHandler()
    
    var body: some View {
            ZStack {
                HeaderView()
                if frameHandler.isRecording{
                    CameraView(frameHandler: frameHandler)
                        .cornerRadius(25)
                        .overlay(EyeMask(yOffset: 200))
                    FooterView(frameHandler: frameHandler)
                }else if frameHandler.isRecording == false {
                    FormView(frameHandler: frameHandler)
                }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
