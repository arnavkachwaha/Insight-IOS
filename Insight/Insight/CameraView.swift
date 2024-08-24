import UIKit
import AVFoundation
import SwiftUI

struct CameraView: UIViewControllerRepresentable {
    @ObservedObject var frameHandler: FrameHandler

    init(frameHandler: FrameHandler) {
        self.frameHandler = frameHandler
    }

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
    private var maskView: UIImageView!
    private let cyclopsProcessor = CyclopsProcessor() // Use the new CyclopsProcessor
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPreviewLayer()
    }
    
    private func setupPreviewLayer() {
        guard let frameHandler = frameHandler, let captureSession = frameHandler.captureSession else { return }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
    }
}

struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        CameraView(frameHandler: FrameHandler())
    }
}
