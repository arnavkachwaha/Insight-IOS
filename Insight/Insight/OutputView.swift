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
    var onRedo: () -> Void
    var onProceed: () -> Void
    var videoUrl: URL?
    var graphUrl: URL?
    init(videoUrl: URL?, graphUrl: URL?, onRedo: @escaping () -> Void, onProceed: @escaping () -> Void) {
        self.videoUrl = videoUrl
        self.graphUrl = graphUrl
        self.onRedo = onRedo
        self.onProceed = onProceed
    }
    
    var body: some View {
        ZStack {
            Color(red: 240/255, green: 240/255, blue: 240/255)
                .edgesIgnoringSafeArea(.all)
            VStack {
                VideoPlayer(videoURL: self.videoUrl!)
                    .frame(width: 390, height: 320)
                    .padding(.bottom, 0.5)
                
                AsyncImage(url: graphUrl) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 390, height: 315)
                        
                    } else {
                        Color.red
                            .frame(width: 390, height: 315)
                    }
                }
                
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
                    }.padding(.leading, 25)
                        .padding(.top, 5)
                        .padding(.bottom, 10)
                    
                    Spacer()
                    
                    Button(action: {
                        onProceed()
                    }) {
                        Text("Proceed")
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(20)
                    }.padding(.trailing, 25)
                        .padding(.top, 5)
                        .padding(.bottom, 10)
                    
                }
                
                Spacer()
            }.padding(.top, 45)
            HeaderView()
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
