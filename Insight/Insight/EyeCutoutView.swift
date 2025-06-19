//
//  EyeMask.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 7/13/24.
//

import SwiftUI

struct EyeCutoutView: View {
    var currentView: String
    var yOffset: CGFloat
    var detectedBox: CGRect?
    
    var body: some View {
        GeometryReader { geometry in
            let eyeWidth = geometry.size.width / 1.15
            
            ZStack {
                Color.gray.opacity(0.4)
                
                let eyeShape = EyePathProvider.makeShape(
                    currentView: currentView,
                    yOffset: yOffset
                )
                
                eyeShape
                    .fill(Color.black)
                    .blendMode(.destinationOut)
                    .frame(width: geometry.size.width, height: geometry.size.height)

                
                // If a detected bounding box exists, check for overlap.
                if let detectedBox = detectedBox {
                    // Get the bounding box of the EyeShape's path (the eye cutout).
                    let eyePath = eyeShape.path(in: CGRect(origin: .zero, size: geometry.size))
                    let eyePathRect = eyePath.cgPath.boundingBox
                    
                    // Calculate the center points.
                    let eyeCenter = CGPoint(x: eyePathRect.midX, y: eyePathRect.midY)
                    let detectedCenter = CGPoint(x: detectedBox.midX, y: detectedBox.midY)
                    
                    // Calculate the distance between the centers.
                    let centerDistance = hypot(eyeCenter.x - detectedCenter.x, eyeCenter.y - detectedCenter.y)
                    
                    // Define a threshold for "nearness" of centers (15% of the eye width).
                    let distanceThreshold = currentView == "VOMS" ? eyeWidth * 0.5 : eyeWidth * 0.15
                    
                    // Compute the intersection between the eye cutout and the detected rectangle.
                    let intersectionRect = eyePathRect.intersection(detectedBox)
                    let intersectionArea = intersectionRect.width * intersectionRect.height
                    let detectedArea = detectedBox.width * detectedBox.height
                    let intersectionRatio = detectedArea > 0 ? intersectionArea / detectedArea : 0

                    if centerDistance < distanceThreshold && intersectionRatio > 0.65 {
                        eyeShape
                            .stroke(Color.green, lineWidth: 5)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                    }
                }
                
//                Rectangle()
//                    .stroke(Color.red, lineWidth: 2)
//                    .frame(width: detectedBox?.width, height: detectedBox?.height)
//                    .position(x: detectedBox?.midX ?? 100, y: detectedBox?.midY ?? 100)
                
            }
            .compositingGroup() // Needed for the blend mode.
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .ignoresSafeArea()
    }
}

struct EyeCutout_Previews: PreviewProvider {
    static var previews: some View {
        EyeCutoutView(
            currentView: "PLR",
            yOffset: 200,
            detectedBox: CGRect(x: 30, y: 80, width: 350, height: 240)
        )
    }
}
