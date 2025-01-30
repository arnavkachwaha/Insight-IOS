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
            Color(red: 240/255, green: 240/255, blue: 240/255).edgesIgnoringSafeArea(.all)
            VideoPlayer(videoURL: self.videoUrl!)
                .frame(width: 390, height: 320)
                .padding(.bottom, 0.5)
            VStack {
                Spacer()
                
                HStack {
                    Button(action: {
                        onRedo()
                    }) {
                        Text("Redo")
                            .font(.headline)
                            .foregroundColor(.black)
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
                            .foregroundColor(.black)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(20)
                    }.padding(.trailing, 20)
                        .padding(.bottom, 25)
                    
                }
            }
            
            HeaderView()
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
