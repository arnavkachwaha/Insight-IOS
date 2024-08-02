//
//  FooterView.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 6/26/24.
//


import SwiftUI

struct FooterView: View {
    @ObservedObject var frameHandler: FrameHandler
    @State private var isRecording = false
    @State private var zoomLevel: CGFloat = 1.0 // Default zoom level
    @State private var isFlashOn = false // Flash status
    
    var body: some View {
        VStack {
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
            
            HStack(spacing: 30) {
                // Zoom 1x button
                Button(action: {
                    zoomLevel = 1.0
                    frameHandler.setZoom(scale: zoomLevel)
                }) {
                    Text("1x")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                .frame(width: 30, height: 30, alignment: .center)
                .background(Color.white)
                .cornerRadius(100)
                .padding(.leading, 10)
                
                // Zoom 2x button
                Button(action: {
                    zoomLevel = 2.0
                    frameHandler.setZoom(scale: zoomLevel)
                }) {
                    Text("2x")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                .frame(width: 30, height: 30, alignment: .center)
                .background(Color.white)
                .cornerRadius(100)
                
                // Zoom 3x button
                Button(action: {
                    zoomLevel = 3.0
                    frameHandler.setZoom(scale: zoomLevel)
                }) {
                    Text("3x")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                .frame(width: 30, height: 30, alignment: .center)
                .background(Color.white)
                .cornerRadius(100)
                
                Spacer()
                
                // Flash button
                Button(action: {
                    isFlashOn.toggle()
                    frameHandler.setFlash(on: isFlashOn)
                }) {
                    Image(systemName: isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(isFlashOn ? .yellow : .gray)
                }
                .padding(.trailing, 10)
                
                // Gallery button
                Button(action: openPhotosApp) {
                    Label {
                    } icon: {
                        Image(systemName: "photo")
                            .font(.title)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
            }
        }
        .preferredColorScheme(.dark)
        .padding(.bottom, 20)
    }
    
    // Function to open the Photos app
    func openPhotosApp() {
        if let url = URL(string: "photos-redirect://") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}

//#Preview {
//    FooterView(frameHandler: FrameHandler())
//}

struct FooterView_Previews: PreviewProvider {
    static var previews: some View {
        FooterView(frameHandler: FrameHandler())
    }
}
