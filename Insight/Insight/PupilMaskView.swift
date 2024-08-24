import UIKit
import AVFoundation
import SwiftUI
import Combine

struct PupilMaskView: UIViewControllerRepresentable {
    @ObservedObject var frameHandler: FrameHandler

    init(frameHandler: FrameHandler) {
        self.frameHandler = frameHandler
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = PupilMaskViewController()
        controller.frameHandler = frameHandler
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

class PupilMaskViewController: UIViewController {
    var frameHandler: FrameHandler?
    private var imageView: UIImageView!
    private var cancellable: AnyCancellable?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupImageView()
        observeFrameUpdates()
    }

    private func setupImageView() {
        imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        
        // Constraints to position the image view
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            imageView.widthAnchor.constraint(equalToConstant: 300),
            imageView.heightAnchor.constraint(equalToConstant: 200)
        ])
    }
    
    private func observeFrameUpdates() {
        // Ensure frameHandler is available
        guard let frameHandler = frameHandler else { return }
        
        // Observe the frame changes
        cancellable = frameHandler.$frame
               .compactMap { $0 } // Ignore nil values
               .map { UIImage(cgImage: $0) } // Convert CGImage to UIImage
               .assign(to: \.image, on: imageView)
    }
    
    deinit {
        cancellable?.cancel()
    }
}

struct PupilMaskView_Previews: PreviewProvider {
    static var previews: some View {
        PupilMaskView(frameHandler: FrameHandler())
    }
}
