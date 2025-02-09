//
//  CameraView.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 6/27/24.
//

import SwiftUI
import AVFoundation

struct CameraView: View {
    @ObservedObject var frameHandler: FrameHandler
    
    var body: some View {
        ZStack {
            Color(.black).edgesIgnoringSafeArea(.all)
            if frameHandler.isSessionReady {
                CameraFeedView(frameHandler: frameHandler)
            } else {
                Text("Loading...")
                    .foregroundColor(.white)
            }
        }
        .ignoresSafeArea()
    }
}

struct CameraFeedView: UIViewControllerRepresentable {
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

#Preview {
    CameraView(frameHandler: FrameHandler())
}
