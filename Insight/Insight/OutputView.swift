//
//  PlrView.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 10/1/24.
//

import AVKit
import UIKit
import SwiftUI

struct OutputView: View {
    var videoUrl: URL?
    var graphUrl: URL?
    var onRedo: () -> Void
    var onProceed: () -> Void
    
    init(videoUrl: URL?, graphUrl: URL?, onRedo: @escaping () -> Void, onProceed: @escaping () -> Void) {
        self.onRedo = onRedo
        self.videoUrl = videoUrl
        self.graphUrl = graphUrl
        self.onProceed = onProceed
    }
    
    var body: some View {
        ZStack {
            Color(red: 250/255, green: 250/255, blue: 250/255).edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack {
                    HeaderView()
                    Spacer()
                    
                    VideoPlayerView(videoUrl: self.videoUrl)
                    ImageView(imageUrl: self.graphUrl)
                    
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
                        }.padding(.leading, 40)
                            .padding(.top, 5)
                            .padding(.bottom, 10)
                        
                        Spacer()
                        
                        Button(action: {
                            onProceed()
                        }) {
                            Text("Proceed")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(20)
                        }.padding(.trailing, 40)
                            .padding(.top, 5)
                            .padding(.bottom, 10)
                    }
                }
            }.padding(.all, 1)
        }
        
    }
}

#Preview {
    OutputView(
        videoUrl: URL(string: "https://example.com/video.mov"),
        graphUrl: URL(string: "https://example.com/graph.png"),
        onRedo: {
            print("Redo pressed")
        },
        onProceed: {
            print("Proceed pressed")
        }
    )
}
