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
            if frameHandler.isSessionReady {
                CameraFeedView(frameHandler: frameHandler)
            } else {
                Text("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                    .foregroundColor(.white)
            }
        }
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
    private var playerLayer: AVPlayerLayer!
    private var boundingBoxLayer: CAShapeLayer?  // Store a reference to the bounding box layer
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPreviewLayer()
    }
    
    private func setupPreviewLayer() {
        guard let frameHandler = frameHandler else { return }

        #if targetEnvironment(simulator)
        // Ensure the FrameHandler's AVPlayer is used
        guard let player = frameHandler.player else {
            print("Player not found in FrameHandler")
            return
        }
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = view.bounds
        playerLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(playerLayer)

        #else
        // For physical devices, use the camera's preview layer
        guard let captureSession = frameHandler.captureSession else { return }
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        #endif
        
        // Example: Add the bounding box layer
           if let boundingBoxRect = frameHandler.boundingBoxRect {
               addBoundingBoxLayer(with: boundingBoxRect)
           }

           // Observe updates to the bounding box from FrameHandler
           frameHandler.onBoundingBoxUpdated = { [weak self] newBoundingBox in
               self?.updateBoundingBoxLayer(with: newBoundingBox)
           }
    }
    
    
    // Add the bounding box layer to the view
      private func addBoundingBoxLayer(with boundingBoxRect: CGRect) {
          let boundingBoxLayer = CAShapeLayer()
          boundingBoxLayer.frame = boundingBoxRect
          boundingBoxLayer.borderColor = UIColor.green.cgColor
          boundingBoxLayer.borderWidth = 2
          view.layer.addSublayer(boundingBoxLayer)
          self.boundingBoxLayer = boundingBoxLayer  // Store a reference to it
      }

      // Update the bounding box layer when the frameHandler's bounding box is updated
      private func updateBoundingBoxLayer(with boundingBoxRect: CGRect?) {
          guard let boundingBoxRect = boundingBoxRect else { return }

          if let existingLayer = boundingBoxLayer {
              existingLayer.frame = boundingBoxRect  // Update the existing layer's frame
          } else {
              addBoundingBoxLayer(with: boundingBoxRect)  // If it doesn't exist, add it
          }
      }
}

#Preview {
    CameraView(frameHandler: FrameHandler())
}
