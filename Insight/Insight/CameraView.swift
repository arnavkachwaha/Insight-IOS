import SwiftUI
import AVFoundation

struct CameraView: UIViewControllerRepresentable {
    @ObservedObject var frameHandler: FrameHandler

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = CameraViewController()
        controller.frameHandler = frameHandler
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

class CameraViewController: UIViewController {
    var frameHandler: FrameHandler?
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var imageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupPreviewLayer()
        setupImageView()
    }
    
    private func setupPreviewLayer() {
        guard let frameHandler = frameHandler, let captureSession = frameHandler.captureSession else { return }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
    }

    private func setupImageView() {
        imageView = UIImageView(image: UIImage(named: "vid10.frame9"))
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)

        // Constraints to position the image view
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 200),
            imageView.heightAnchor.constraint(equalToConstant: 200)
        ])
    }
}

struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        CameraView(frameHandler: FrameHandler())
    }
}
