//
//  EyeMask.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 7/13/24.
//

import SwiftUI

struct EyeShape: Shape {
    var yOffset: CGFloat
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width / 1.15
        let height = rect.height / 2.15
        
        // Center horizontally.
        let xOffset = (rect.width - width) / 2
        
        // Draw an "eye-like" shape.
        path.move(to: CGPoint(x: xOffset, y: yOffset))
        path.addQuadCurve(
            to: CGPoint(x: xOffset + width, y: yOffset),
            control: CGPoint(x: xOffset + width / 2, y: yOffset - height / 2)
        )
        path.addQuadCurve(
            to: CGPoint(x: xOffset, y: yOffset),
            control: CGPoint(x: xOffset + width / 2, y: yOffset + height / 2)
        )
        return path
    }
}

struct EyeCutoutView: View {
    var yOffset: CGFloat
    var detectedBox: CGRect?
    
    var body: some View {
        GeometryReader { geometry in
            let eyeWidth = geometry.size.width / 1.15
            let eyeHeight = geometry.size.height / 2.15
            let xOffset = (geometry.size.width - eyeWidth) / 2
            let eyeRect = CGRect(x: xOffset, y: yOffset - eyeHeight / 2, width: eyeWidth, height: eyeHeight)
            
            ZStack {
                Color.gray.opacity(0.2)
                
                EyeShape(yOffset: yOffset)
                    .fill(Color.black)
                    .blendMode(.destinationOut)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                
                // If a detected bounding box exists, check for overlap.
                if let detectedBox = detectedBox {
                    // Get the bounding box of the EyeShape's path (the eye cutout).
                    let eyePath = EyeShape(yOffset: yOffset).path(in: eyeRect)
                    let eyePathRect = eyePath.cgPath.boundingBox
                    
                    // Calculate the center points.
                    let eyeCenter = CGPoint(x: eyePathRect.midX, y: eyePathRect.midY)
                    let detectedCenter = CGPoint(x: detectedBox.midX, y: detectedBox.midY)
                    
                    // Calculate the distance between the centers.
                    let centerDistance = hypot(eyeCenter.x - detectedCenter.x, eyeCenter.y - detectedCenter.y)
                    
                    // Define a threshold for "nearness" of centers (15% of the eye width).
                    let distanceThreshold = eyeRect.width * 0.15
                    
                    // Compute the intersection between the eye cutout and the detected rectangle.
                    let intersectionRect = eyePathRect.intersection(detectedBox)
                    let intersectionArea = intersectionRect.width * intersectionRect.height
                    let detectedArea = detectedBox.width * detectedBox.height
                    let intersectionRatio = detectedArea > 0 ? intersectionArea / detectedArea : 0
                    
                    if centerDistance < distanceThreshold && intersectionRatio > 0.65 {
                        EyeShape(yOffset: yOffset)
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
            yOffset: 200,
            detectedBox: CGRect(x: 30, y: 80, width: 350, height: 240)
        )
    }
}
