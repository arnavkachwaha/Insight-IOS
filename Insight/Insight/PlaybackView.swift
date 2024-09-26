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
            VideoPlayerView(videoURL: self.videoUrl!)
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
                            .cornerRadius(10)
                    }

                    Spacer()

                    Button(action: {
                        onUse()
                    }) {
                        Text("Use")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(10)
                        }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
                }
        }
    }
}


struct VideoPlayerView: UIViewControllerRepresentable {
    let videoURL: URL

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let playerViewController = AVPlayerViewController()
        let player = AVPlayer(url: videoURL)

        playerViewController.player = player
        playerViewController.showsPlaybackControls = false  // Hide controls

        player.play()

        // Observe video completion and reset player
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { _ in
            player.seek(to: .zero)
        }

        return playerViewController
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}

