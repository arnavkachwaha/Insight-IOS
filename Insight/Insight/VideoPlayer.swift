//
//  VideoPlayerView.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 10/1/24.
//

import SwiftUI
import AVKit

struct VideoPlayer: UIViewControllerRepresentable {
    let videoURL: URL
    var zoomLevel: AVLayerVideoGravity
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let playerViewController = AVPlayerViewController()
        let player = AVPlayer(url: videoURL)
        
        playerViewController.player = player
        playerViewController.showsPlaybackControls = false  // Hide controls
        
        player.play()
        
        // Observe video completion and reset player
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { _ in
            player.seek(to: .zero)
            player.play()
        }
        
        return playerViewController
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        uiViewController.videoGravity = zoomLevel
    }
}

#Preview {
    VideoPlayer(videoURL: .init(string: "videod.mp4")!, zoomLevel: AVLayerVideoGravity.resizeAspectFill)
}
