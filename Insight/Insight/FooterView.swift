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
    FooterView(frameHandler: FrameHandler())
}


// Gallery button
//            HStack {
//                Spacer()
//                Button(action: openPhotosApp) {
//                    Label {
//                    } icon: {
//                        Image(systemName: "photo")
//                            .font(.title)
//                    }
//                    .foregroundColor(.white)
//                    .padding(.horizontal, 20)
//                    .padding(.vertical, 12)
//                }
//            }


// Function to open the Photos app
//    func openPhotosApp() {
//        if let url = URL(string: "photos-redirect://") {
//            UIApplication.shared.open(url, options: [:], completionHandler: nil)
//        }
//    }
