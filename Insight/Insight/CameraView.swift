//
//  CameraView.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 6/27/24.
//

import Combine
import SwiftUI
import AVFoundation

struct CameraView: View {
    @ObservedObject var frameHandler: FrameHandler
    @Binding var detectedBox: CGRect?
    
    var body: some View {
        ZStack {
            Color(.black).edgesIgnoringSafeArea(.all)
            if frameHandler.isSessionReady && frameHandler.currentView == "PLR"{
                CameraFeedView(frameHandler: frameHandler, detectedBox: $detectedBox)
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
    @Binding var detectedBox: CGRect?
    
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = CameraViewController()
        controller.frameHandler = frameHandler
        
        // Subscribe to the camera's bounding box store.
        controller.boundingBoxStore.$boundingBox
            .receive(on: DispatchQueue.main)
            .sink { box in
                detectedBox = box
            }
            .store(in: &context.coordinator.cancellables)
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var cancellables = Set<AnyCancellable>()
    }
}

class BoundingBoxStore: ObservableObject {
    @Published var boundingBox: CGRect? = nil
}

class CameraViewController: UIViewController {
    var frameHandler: FrameHandler?
    var boundingBoxStore = BoundingBoxStore()
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var boundingBoxLayer: CAShapeLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPreviewLayer()
        observeBoundingBoxChanges()
    }
    
    private func setupPreviewLayer() {
        guard let frameHandler = frameHandler, let captureSession = frameHandler.captureSession else { return }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
    }
    
    private func observeBoundingBoxChanges() {
        frameHandler?.$boundingBox.sink { [weak self] boundingBox in
            guard let self = self else { return }
            self.updateBoundingBox(boundingBox)
        }
        .store(in: &cancellables)
    }
    
    private func convertRectFromNormalizedCoordinates(_ rect: CGRect, in view: UIView) -> CGRect {
        let x = rect.origin.x * view.bounds.width
        let y = (1 - rect.origin.y - rect.height) * view.bounds.height
        let width = rect.size.width * view.bounds.width
        let height = rect.size.height * view.bounds.height
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    
    private func updateBoundingBox(_ boundingBox: CGRect?) {
        // Remove the previous bounding box layer
        boundingBoxLayer?.removeFromSuperlayer()
        guard let boundingBox = boundingBox else { return }
        
        // Convert the normalized bounding box to the view's coordinate space.
        let convertedRect = convertRectFromNormalizedCoordinates(boundingBox, in: self.view)
        
        boundingBoxStore.boundingBox = convertedRect
    }
    
    private var cancellables = Set<AnyCancellable>()
}

#Preview {
    CameraView(frameHandler: FrameHandler(), detectedBox: .constant(nil))
}
