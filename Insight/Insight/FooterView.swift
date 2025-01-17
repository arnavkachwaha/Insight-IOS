//
//  RecordButtonView.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 6/26/24.
//

import SwiftUI

struct FooterView: View {
    @ObservedObject var frameHandler: FrameHandler
    @State private var isRecording = false
    var onRecordingStateChanged: (Bool) -> Void
    
    var body: some View {
        VStack {
            Spacer()
            // Recording button
            Button(action: {
                isRecording.toggle()
                if isRecording {
                    frameHandler.startRecording()
                } else {
                    frameHandler.stopRecording()
                }
                onRecordingStateChanged(isRecording)
            }) {
                Image(systemName: isRecording ? "stop.circle" : "record.circle")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .padding(10)
                    .foregroundColor(isRecording ? .red : .blue)
            }
            
        }
        .preferredColorScheme(.dark)
        .padding(.bottom, 20)
    }
    
}

#Preview {
    FooterView(frameHandler: FrameHandler(), onRecordingStateChanged: { _ in })
}
