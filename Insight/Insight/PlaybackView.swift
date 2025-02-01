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
            Color(red: 250/255, green: 250/255, blue: 250/255).edgesIgnoringSafeArea(.all)
            
            VStack {
                HeaderView()
                Spacer()
                
                VideoPlayerView(videoUrl: self.videoUrl)
                
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
                    }.padding(.all, 40)
                    
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
                    }.padding(.all, 40)
                    
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
