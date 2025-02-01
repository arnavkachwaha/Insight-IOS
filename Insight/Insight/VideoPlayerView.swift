//
//  VideoPlayerView.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 2/1/25.
//

import SwiftUI
import AVFoundation

struct VideoPlayerView: View {
    var videoUrl: URL?
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.gray.opacity(0.5))
                .frame(width: 390, height: 300)
                .cornerRadius(20)
            
            if let videoUrl = videoUrl {
                VideoPlayer(videoURL: videoUrl, zoomLevel: AVLayerVideoGravity.resizeAspectFill)
                    .frame(width: 380, height: 280)
                    .cornerRadius(20)
            }
        }
        .padding(.all, 2.5)
    }
}

#Preview {
    Group {
        VideoPlayerView(videoUrl: URL(string: "https://example.com/video.mov"))        
    }
}
