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
                    // Compute the intersection between the eye area and the detected box.
                    let intersection = eyeRect.intersection(detectedBox)
                    let eyeArea = eyeRect.width * eyeRect.height
                    let intersectionArea = intersection.width * intersection.height
                    
                    // If more than 50% of the eye cutout is overlapped, draw a green outline.
                    if eyeArea > 0, (intersectionArea / eyeArea) > 0.5 {
                        EyeShape(yOffset: yOffset)
                            .stroke(Color.green, lineWidth: 5)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                    }
                }
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
            detectedBox: CGRect(x: 37.5, y: 66.6, width: 300, height: 266.8)
        )
    }
}
