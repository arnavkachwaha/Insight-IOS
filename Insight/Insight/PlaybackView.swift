//
//  PlaybackView.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 7/27/24.
//

import SwiftUI
import AVKit

struct PlaybackView: View {
    
    @ObservedObject var viewModel: ContentViewModel
    var onRedo: () -> Void

    init(viewModel: ContentViewModel, onRedo: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onRedo = onRedo
    }

    var body: some View {
        ZStack {
            if let videoURL = viewModel.videoURL {
                VideoPlayerView(videoURL: videoURL)
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

struct PlaybackView_Previews: PreviewProvider {
    static var previews: some View {
        let mockViewModel = ContentViewModel(frameHandler: FrameHandler())
        PlaybackView(viewModel: mockViewModel, onRedo: {
            print("Redo pressed")
        })
    }
}
