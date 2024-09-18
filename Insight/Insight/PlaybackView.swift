import SwiftUI
import AVKit

struct PlaybackView: View {
    let videoURL: URL
    var onRedo: () -> Void
    var onUse: () -> Void

    var body: some View {
        ZStack {
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

        player.play()  // Automatically start video playback

        // Observe video completion and reset player
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { _ in
            player.seek(to: .zero)
        }

        return playerViewController
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}

