//
//  PlaybackView.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 7/27/24.
//

import SwiftUI
import AVKit

struct PlaybackView: View {
    var onRedo: () -> Void
    var onUse: () -> Void
    var videoUrl: URL?
    
    init(videoUrl: URL?, onRedo: @escaping () -> Void, onUse: @escaping () -> Void) {
        self.videoUrl = videoUrl
        self.onRedo = onRedo
        self.onUse = onUse
    }
    
    var body: some View {
        ZStack {
            VideoPlayer(videoURL: self.videoUrl!)
            VStack {
                Spacer()
                
                HStack {
                    Button(action: {
                        onRedo()
                    }) {
                        Text("Redo")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(20)
                    }.padding(.leading, 20)
                        .padding(.bottom, 25)
                    
                    Spacer()
                    
                    Button(action: {
                        onUse()
                    }) {
                        Text("Analyze")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(20)
                    }.padding(.trailing, 20)
                        .padding(.bottom, 25)
                    
                }
            }
        }
    }
}

#Preview {
    PlaybackView(
        videoUrl: URL(string: "https://example.com/video.mov"),
        onRedo: {
            print("Redo pressed")
        },
        onUse: {
            print("Use")
        }
    )
}




